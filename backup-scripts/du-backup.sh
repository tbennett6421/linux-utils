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
GPG_PASSWORD='setme'                                                        ##!!
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
HASROLE_LAMP=$BOOL_FALSE	## Has Apache, MySQL, PHP?
HASROLE_ZFS=$BOOL_FALSE 	## Has ZFS and ZPools?

## LOCAL_BKUP "should" contain the vast majority of directories/files to backup
## special directories/files that are unique should be managed through a HASROLE hook
LOCAL_BKUP=(
'/etc/bind/'
'/etc/cron.d'
'/etc/cron.daily'
'/etc/cron.hourly'
'/etc/cron.monthly'
'/etc/crontab'
'/etc/cron.weekly'
'/etc/exports/'
'/etc/fstab'
'/etc/group'
'/etc/hostname'
'/etc/hosts'
'/etc/hosts.allow'
'/etc/hosts.deny'
'/etc/logrotate.conf'
'/etc/logrotate.d/'
'/etc/lsb-release'
'/etc/network/'
'/etc/nsswitch.conf'
'/etc/pam.conf'
'/etc/pam.d/'
'/etc/passwd'
'/etc/rc.local'
'/etc/rsync-exclude-list.txt'
'/etc/rsyslog.conf'
'/etc/rsyslog.d/'
'/etc/salt/'
'/etc/samba/'
'/etc/security/'
'/etc/shells/'
'/etc/skel/'
'/etc/ssh'
'/etc/ssmtp/'
'/etc/sudoers'
'/etc/sudoers.d/'
'/usr/local/bin/'
'/var/prtg/'
'/var/spool/cron/crontabs/'
'/home/'
'/root/'
)

########################################################################
### Begin Constants and Definitions
########################################################################
EXIT_ERR_SUCCESS=0
EXIT_ERR_USAGE=1
EXIT_ERR_SUDO=2
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
NOHUP=`which nohup`
GREP=`which grep`
MKDIR=`which mkdir`
TIME=`which time`
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
    
    -f|--full            sets backup mode to full (default)
    -i|--incremental     sets backup mode to incremental
    -d|--debug           enable debugging output
    -h|--help            prints this help menu.
    -g|--gpg <file>      specifies a file containing the passphrase to set
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

function set_GPG(){
    if [ -e "$F_GPG_FILE" ]; then 
        GPG_PASSWORD=`$CAT $F_GPG_FILE`
    else
        echo "$F_GPG_FILE does not exist"
        exit
    fi

}

########################################################################
### Begin program execution and logic
########################################################################

###### CLI Parsing ######
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -f|--full)
    F_FULL="true"
    shift
    ;;
    -i|--incremental)
    F_INCREMENTAL="true"
    shift
    ;;
    -d|--debug)
    F_DEBUG="true"
    shift
    ;;
    -h|--help)
    F_HELP="true"
    shift
    ;;
    -g|--gpg)
    F_GPG="true"
    if [ -z "$2" ]; then
        usage
    else
        F_GPG_FILE=$2;
    fi
    shift 2
    ;;
    *)	## unknown option
    echo "unknown option $key"
    exit
    shift
    ;;	## do nothing
esac
done
###### END CLI Parsing ######

if [ "$F_INCREMENTAL" ] && [ "$F_FULL" ]; then
	fatal "Unable to do an incremental and full backup set"
	usage
fi
if [ "$F_HELP" ]; then usage; fi

## Set flags at runtime for program behavior
if [ $B_MAIL -eq $BOOL_TRUE ]; then F_MAIL="true"; fi
if [ "$F_INCREMENTAL" ]; then F_MODE="incremental"; fi
if [ "$F_FULL" ]; then F_MODE="full"; fi
if [ -z "$F_MODE" ]; then F_MODE="full"; fi
if [ "$F_GPG" ]; then set_GPG; fi

## Check for superuser, required to access restricted files for backup
if [ "$EUID" -ne 0 ]; then 
	echo "This program must be run as a privileged user"
  	exit $EXIT_ERR_SUDO
fi

## @todo: check for all programs required to run this program
##        --fatal errors when duplicity is not installed, possible remediate

## Create log directory if not exist
$MKDIR $LOG_DIR > /dev/null 2>&1

## Execute HASROLE hooks ##

if [ $HASROLE_LAMP -eq $BOOL_TRUE ]; then
	## Ensure that root can login to mysql without requiring a password
	## @link https://serverfault.com/questions/563714
	MYSQLDUMP=`which mysqldump`
	`$MYSQLDUMP --all-databases > /root/mysql_backup/alldb.sql`

	LOCAL_BKUP+=('/etc/php/')
	LOCAL_BKUP+=('/etc/mysql/')
	LOCAL_BKUP+=('/etc/ssl/')
	LOCAL_BKUP+=('/etc/apache2/')
	LOCAL_BKUP+=('/var/www/')
fi

if [ $HASROLE_ZFS -eq $BOOL_TRUE ]; then
	## ZFS info is stored in the pools, have to extract it
	ZFS=`which zfs`
	ZPOOL=`which zpool`
	`$ZFS list > /tmp/zfs_list`
	`$ZPOOL status > /tmp/zpool_status`

	LOCAL_BKUP+=('/tmp/zfs_list')
	LOCAL_BKUP+=('/tmp/zpool_status')
	LOCAL_BKUP+=('/etc/zfs/')
	LOCAL_BKUP+=('/etc/smartmontools/')
	LOCAL_BKUP+=('/etc/smartd.conf')

fi

## After HASROLE hooks have finished, and LOCAL_BKUP has been
## finalized, transform LOCAL_BKUP into a duplicity include/exclude 
## string to create a single backup chain.
DUPL_BKUP=()
for i in "${LOCAL_BKUP[@]}"
do
	var="--include $i"
	DUPL_BKUP+=("$var")	
done

DUPL_BKUP_STR="$F_MODE -v4 --ssh-options='-oIdentityFile=$SSH_PR_KEY' "
DUPL_BKUP_STR+="${DUPL_BKUP[*]}"        ## print entire array on one-line
DUPL_BKUP_STR+=" --exclude '**' / "     ## space, exclude option
DUPL_BKUP_STR+="$REMOTE_URI"

info "Loaded LOCAL_BKUP"
if [ "$F_DEBUG" ]; then
	debug "LOCAL_BKUP => ${LOCAL_BKUP[*]}"
	debug "DUPL_BKUP => ${DUPL_BKUP[*]}"
	debug "DUPL_BKUP_STR => $DUPL_BKUP_STR"
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
		debug "exporting PASSPHRASE"
		debug "exec \\ $NOHUP $TIME $DUPLICITY $DUPL_BKUP_STR 2>&1 | $TEE $LOG_FILE"
		debug "unsetting PASSPHRASE"
	fi
	
	export PASSPHRASE=$GPG_PASSWORD
	eval $NOHUP $TIME $DUPLICITY $DUPL_BKUP_STR 2>&1 | $TEE $LOG_FILE
	unset PASSPHRASE
else
	info "Running from non-interactive terminal"
	if [ "$F_DEBUG" ]; then
		debug "exporting PASSPHRASE"
		debug "exec \\ $TIME $DUPLICITY $DUPL_BKUP_STR 2>&1 | $TEE $LOG_FILE"
		debug "unsetting PASSPHRASE"
	fi
	
	export PASSPHRASE=$GPG_PASSWORD
	eval $TIME $DUPLICITY $DUPL_BKUP_STR 2>&1 | $TEE $LOG_FILE
	unset PASSPHRASE
fi

RET=`grep "Errors" $LOG_FILE`
# check if error
if [ "$RET" != "Errors 0" ]; then
	msg="There was an unknown error"

	printf "$msg\n";                ## output error msg
	logger "$SCRIPT_NAME: $msg"     ## send to syslog

	mbody=$(ml_output "$msg")       ## compose email
	if [ "$F_MAIL" ]; then
		$MAILER -f "$FROM" -t "$TO" -s "$SUBJ" -b "$mbody"
	fi

	exit $EXIT_ERR_GREP;
else
	exit $EXIT_ERR_SUCCESS;
fi
