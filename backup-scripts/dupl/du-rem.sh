#!/usr/bin/env bash
##
## Author:        Tyler Bennett
## Email:         tbennett6421@gmail.com
## Date:          2017-11-26
## Usage:         rsync-running-config.sh
## Description:   Backup a system using duplicity
##
## Settings required to be user-set will be tagged as follows. ##!!
## This allows required options to be "greppable" using fgrep '##!!'
##			
##
##@@ During refactoring, options to be evaluated for removal
##@@ i.e. not necessary, are marked as follows.
##@@		##@@EXIT_ERR_GREP=4
##@@

BOOL_TRUE=1
BOOL_FALSE=0
HOSTNAME=`which hostname`
HOST=`$HOSTNAME`

################################################################################
### Begin configurable options;
### set options using $BOOL_TRUE, $BOOL_FALSE, 'stringvalues' or integer
################################################################################
SSH_PR_KEY="/home/dr/.ssh/id_rsa"     ## SSH key for remote login           ##!!
REM_USER="dr"                         ## Username for remote system         ##!!
REM_HOST="dr"                         ## Target remote system               ##!!
REM_USER_HOST="$REM_USER@$REM_HOST"
REM_BKUP_BASEDIR="/dr"                                                      ##!!
BACKUP_FORMAT="servers/$HOST/running-config_duplicity"	  ##@@temporary location
REM_BKUP_PATH="$REM_BKUP_BASEDIR/$BACKUP_FORMAT"
REMOTE_URI="pexpect+sftp://$REM_USER_HOST/$REM_BKUP_PATH"
LOG_DIR='/var/log/dr'
B_MAIL=$BOOL_TRUE           ## should this program use email subsystem
PING_COUNT=3                ## number of ICMP packets to send to remote

########################################################################
### Begin Constants and Definitions
########################################################################
EXIT_ERR_SUCCESS=0
EXIT_ERR_USAGE=1
EXIT_ERR_PING=3
EXIT_ERR_SSH=4
EXIT_ERR_GREP=5
##@@# Grep test and rsync errors
##@@GREP_ERROR_TEST="rsync errors"
##@@GREP_ERROR_STR=("rsync: link_stat")

## see your relevant man pages or test using $?
RTC_PING_ISUP=0
RTC_SSH_ERROR=255;
RTC_TTY_IS_TERMINAL=0

## get program paths
DUPLICITY=`which duplicity`
PING=`which ping`
CAT=`which cat`
SSH=`which ssh`
GREP=`which grep`
MKDIR=`which mkdir`
TEE=`which tee`
TTY=`which tty`
DATE=`which date`

`$TTY -s`                   ## exec tty -s and capture exit status,
TTY_SETTING=$?;             ## this will let us detect if running interactively

SCRIPT_NAME=`basename "$0"`
TIMESTAMP=`$DATE +%Y.%m.%d`
LOG_FILE="$LOG_DIR/$TIMESTAMP-$SCRIPT_NAME.log"

if [ $B_MAIL -eq $BOOL_TRUE ]; then
	FROM="setme"   ##!!
	TO="setme"     ##!!
	SUBJ="$HOST: $SCRIPT_NAME: error"
	MAILER=`which pygmail`
fi

#######################################################
### Begin definitions
#######################################################
function info()  { echo "[INFO]  : $1" ; }
function debug() { echo "[DEBUG] : $1" ; }
function fatal() { echo "[FATAL] : $1" ; }

function usage(){
    $CAT <<-EOF
    $SCRIPT_NAME.sh [flags]
    
    -d|--debug           enable debugging output
    -h|--help            prints this help menu.
EOF
exit $EXIT_ERR_USAGE
}
    
function ml_output(){
	local msg="$1
	
-------------------------------------------------------------------
see the logfile located in $LOG_FILE or check syslog
"
	echo "$msg"
}

function icmpreq(){
	if [ "$F_DEBUG" ]; then
		debug "$PING -q -c $PING_COUNT $1 > /dev/null 2>&1"
	fi
    return `$PING -q -c $PING_COUNT $1 > /dev/null 2>&1`
}

########################################################################
### Begin program execution and logic
########################################################################

###### CLI Parsing ######
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -d|--debug)
    F_DEBUG="true"
    shift
    ;;
    -h|--help)
    F_HELP="true"
    shift
    ;;
    *)	## unknown option
    echo "unknown option $key"
    exit
    shift
    ;;	## do nothing
esac
done
###### END CLI Parsing ######

if [ "$F_HELP" ]; then usage; fi

## Set flags at runtime for program behavior
if [ $B_MAIL -eq $BOOL_TRUE ]; then F_MAIL="true"; fi

## Create log directory if not exist
$MKDIR $LOG_DIR > /dev/null 2>&1

DUPL_STR="remove-all-but-n-full 1 --force -v4 --ssh-options='-oIdentityFile=$SSH_PR_KEY' "
DUPL_STR+="$REMOTE_URI"

if [ "$F_DEBUG" ]; then
	debug "DUPL_STR => $DUPL_STR"
fi

## Performing runtime checks
info "Runtime check [ICMP]"
icmpreq "$REM_HOST"
RTC=$?
if [ $RTC -ne $RTC_PING_ISUP ]; then
	msg="$REM_HOST is not responding to ICMP echo requests ; error code ($RTC)"	
	printf "$msg\n";                ## output error msg
	logger "$SCRIPT_NAME: $msg"     ## send to syslog
	
	mbody=$(ml_output "$msg")       ## compose email
	if [ "$F_MAIL" ]; then
		$MAILER -f "$FROM" -t "$TO" -s "$SUBJ" -b "$mbody"
	fi
	
	exit $EXIT_ERR_PING;

else
	info "Runtime check [ICMP] => passed"
fi

info "Runtime check [SSH]"
if [ "$F_DEBUG" ]; then
	debug "$SSH -i $SSH_PR_KEY $REM_USER_HOST \"exit;\" > /dev/null 2>&1"
fi
$SSH -i $SSH_PR_KEY $REM_USER_HOST "exit;" > /dev/null 2>&1
RTC=$?
if [ $RTC -eq $RTC_SSH_ERROR ]; then
	msg="SSH had issues connecting to $REM_HOST ; exit code ($RTC)"	

	printf "$msg\n";                ## output error msg
	logger "$SCRIPT_NAME: $msg"     ## send to syslog
	
	mbody=$(ml_output "$msg")       ## compose email
	if [ "$F_MAIL" ]; then
		$MAILER -f "$FROM" -t "$TO" -s "$SUBJ" -b "$mbody"
	fi
	
	exit $EXIT_ERR_SSH;

else
	info "Runtime check [SSH] => passed"
fi

## Finished runtime checks, determining TTY and performing backup
if [ "$F_DEBUG" ]; then
	debug "tty -s => $TTY_SETTING"
fi

if [ $TTY_SETTING -eq $RTC_TTY_IS_TERMINAL ]; then
	info "Running from interactive terminal"
	if [ "$F_DEBUG" ]; then
		debug "exec \\ $DUPLICITY $DUPL_STR 2>&1 | $TEE $LOG_FILE"
	fi
	
	eval $DUPLICITY $DUPL_STR 2>&1 | $TEE $LOG_FILE
else
	info "Running from non-interactive terminal"
	if [ "$F_DEBUG" ]; then
		debug "exec \\ $DUPLICITY $DUPL_STR 2>&1 | $TEE $LOG_FILE"
	fi
	
	eval $DUPLICITY $DUPL_STR 2>&1 | $TEE $LOG_FILE
fi
