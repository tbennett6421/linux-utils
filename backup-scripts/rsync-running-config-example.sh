#!/bin/bash
#
# Tyler Bennett <tbennett6421@gmail.com>
# 2016-01-08
#
# This script rsyncs the given folders to a remote location.
# On errors, the script writes to syslog, a flat file, and emails out to the admin
#
# relevant rsync man
# -a, --archive               archive mode; equals -rlptgoD (no -H,-A,-X)
# -v, --verbose               increase verbosity
# -h, --human-readable        output numbers in a human-readable format
# -P                          same as --partial --progress
#     --stats                 give some file-transfer stats
# -R, --relative              use relative path names
# -e, --rsh=COMMAND           specify the remote shell to use
#
# usage: pygmail [-h] -f from -t to -s subject -b body [-a attachment]
#
# Notes:
# --log-file sucks dick ; redirect stdout and stderr to tee for better logging capabilites
#
# @todo: ping rem server and fail loudly if it is down
# @todo: check if the above works or not

# constants
EXIT_ERR_SUCCESS=0
EXIT_ERR_SUDO=1
EXIT_ERR_PING=2
EXIT_ERR_SSH=3
EXIT_ERR_GREP=4
BOOL_TRUE=1
BOOL_FALSE=0

### configurable options
B_DEBUG=$BOOL_TRUE			# be verbose
B_MAIL=$BOOL_TRUE			# use email subsystem
PING_COUNT=3				# ICMP packets to send
HASROLE_CIFS=$BOOL_FALSE	# Serves SMB?
HASROLE_NFS=$BOOL_FALSE		# Serves NFS?
HASROLE_LAMP=$BOOL_FALSE	# Serves webpages?
HASROLE_MDADM=$BOOL_FALSE	# Has MDADM been configured?
HASROLE_ZFS=$BOOL_FALSE		# Has ZFS been configured?
HASROLE_BIND=$BOOL_FALSE	# Acts as DNS Server?

# grep test and rsync errors
GREP_ERROR_TEST="rsync errors"
GREP_ERROR_STR=("rsync: link_stat")

# see your ping man page
PING_ISUP=0

# see your ssh man page
SSH_ERROR_CODE=255;

# tty -s exit statuses
# see your tty man page
TTY_IS_TTY=0
TTY_IS_NOT_TTY=1

# get program paths
RSYNC=`which rsync`
PING=`which ping`
SSH=`which ssh`
NOHUP=`which nohup`
GREP=`which grep`
MKDIR=`which mkdir`
TIME=`which time`
TEE=`which tee`
TTY=`which tty`
DATE=`which date`
HOSTNAME=`which hostname`
HOST=`$HOSTNAME`
if [ $B_MAIL -eq $BOOL_TRUE ]; then 
	MAILER=`which pygmail`
fi
OPTS="-avhP --stats --relative"

# some definitions for logging
SCRIPT_NAME=`basename "$0"`
TS=`$DATE +%Y.%m.%d`

if [ $B_MAIL -eq $BOOL_TRUE ]
then
	# define email info
	FROM="tbennett6421@gmail.com"
	TO="tbennett6421@gmail.com"
	SUBJ="$HOST: $SCRIPT_NAME: error"
fi

#######################################################
#check for root, cuz you can't touch shit without root
if [ "$EUID" -ne 0 ]; then 
	echo "This program must be run as a privileged user"
  	exit $EXIT_ERR_SUDO
fi

# create log directory if not exist
$MKDIR /var/log/dr/ > /dev/null 2>&1

#exec tty -s and capture exit status
`$TTY -s`
TTY_STATS=$?;

# paths to use
PR_KEY="/home/dr/.ssh/id_rsa"
REM_RC_PATH="/home/dr/servers/$HOST/running-config/$TS/"
REM_HOST="dr1"
REM_USER="dr"
REM_USER_HOST="$REM_USER@$REM_HOST"
LOG_FILE="/var/log/dr/$TS-$SCRIPT_NAME.log"

### ensure that ALL of your \ characters have absolutly no 
### whitespace after them, otherwise bash fucks up the rsync line
RC="/etc/ssh/ \
/etc/skel/ \
/etc/network/ \
/etc/hostname \
/etc/hosts \
/etc/group \
/etc/passwd \
/etc/fstab \
/etc/rc.local \
/etc/sudoers \
/usr/local/bin/ \
/var/prtg/ \
/var/spool/cron/crontabs/ \
/home/ \
/root/"

### Use leading spaces
if [ $HASROLE_CIFS -eq $BOOL_TRUE ]; then
	RC+=" /etc/samba/"
fi

if [ $HASROLE_NFS -eq $BOOL_TRUE ]; then
	RC+=" /etc/exports/"
fi

if [ $HASROLE_LAMP -eq $BOOL_TRUE ]; then

	#ensure that root can login to mysql without requiring a password
	#http://serverfault.com/questions/563714/allow-linux-root-user-mysql-root-access-without-password

	#backup mysql database
	MYSQLDUMP=`which mysqldump`
	`$MYSQLDUMP --all-databases > /root/mysql_backup/alldb.sql`
	
	RC+=" /etc/php/ \
		  /etc/mysql/ \
		  /etc/ssl/ \
		  /etc/apache2/ \
		  /var/www/"
fi

if [ $HASROLE_MDADM -eq $BOOL_TRUE ]; then
	RC+=" /etc/mdadm/"
fi

if [ $HASROLE_ZFS -eq $BOOL_TRUE ]; then
	#ZFS info is stored in the pools, have to extract it
	ZFS=`which zfs`
	ZPOOL=`which zpool`
	`$ZFS list > /tmp/zfs_list`
	`$ZPOOL status > /tmp/zpool_status`
	RC+=" /tmp/zfs_list \
		  /tmp/zpool_status"
fi

if [ $HASROLE_BIND -eq $BOOL_TRUE ]; then
	RC+=" /etc/bind/"
fi


if [ $B_DEBUG -eq $BOOL_TRUE ]; then
	echo "[Info]  : loaded RC local configs"
	echo "[DEBUG] : RC => $RC"
fi

function icmpreq(){
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then
		echo "[DEBUG] : $PING -q -c $PING_COUNT $1 > /dev/null 2>&1"
	fi
    return `$PING -q -c $PING_COUNT $1 > /dev/null 2>&1`
}

# runtime check; can we ping the remote server
if [ $B_DEBUG -eq $BOOL_TRUE ]; then
	echo "[Info]  : runtime check [icmp]"
fi
icmpreq "$REM_HOST"
RTC=$?
if [ $RTC -ne $PING_ISUP ]; then
	# fail loudly
	msg="$REM_HOST is not responding to ICMP echo requests ; error code ($RTC)"
	
	# echo to stdout
	printf "$msg\n";
	
	# echo to syslog
	logger "$SCRIPT_NAME: $msg"

	msg="$msg
	
-------------------------------------------------------------------
see the logfile located in $LOG_FILE or check syslog
"

	# email error to me
	$MAILER -f $FROM -t $TO -s "$SUBJ" -b "$msg"
	
	exit $EXIT_ERR_PING;

else
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then
		echo "[Info]  : runtime check [icmp] => passed"
	fi
fi

#runtime check; can we ssh to the remote server
if [ $B_DEBUG -eq $BOOL_TRUE ]; then
	echo "[Info]  : runtime check [ssh]"
	echo "[DEBUG] : $SSH -i $PR_KEY $REM_USER_HOST \"exit;\" > /dev/null 2>&1"
fi
$SSH -i $PR_KEY $REM_USER_HOST "exit;" > /dev/null 2>&1
RTC=$?
if [ $RTC -eq $SSH_ERROR_CODE ]; then
	# fail loudly
	msg="ssh had issues connecting to $REM_HOST ; exit code ($RTC)"
	
	# echo to stdout
	printf "$msg\n";
	
	# echo to syslog
	logger "$SCRIPT_NAME: $msg"

	msg="$msg
	
-------------------------------------------------------------------
see the logfile located in $LOG_FILE or check syslog
"

	# email error to me
	$MAILER -f $FROM -t $TO -s "$SUBJ" -b "$msg"
	
	exit $EXIT_ERR_SSH;

else
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then
		echo "[Info]  : runtime check [ssh] => passed"
	fi
fi

if [ $B_DEBUG -eq $BOOL_TRUE ]; then 
	echo "[DEBUG] : tty -s => $TTY_STATS"
fi

if [ $B_DEBUG -eq $BOOL_TRUE ]; then 
	if [ $TTY_STATS -ne $TTY_IS_TTY ]; then
		echo "[INFO]  : not running from interactive terminal [cron]"	
	fi
fi

if [ $TTY_STATS -eq $TTY_IS_TTY ]; then
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then 
		echo "[INFO]  : running from interactive terminal"
		echo "[DEBUG] : exec \\ $NOHUP $TIME $RSYNC $OPTS -e \"ssh -i $PR_KEY\" $RC $REM_USER_HOST:$REM_RC_PATH 2>&1 | $TEE $LOG_FILE"
	fi
	$NOHUP $TIME $RSYNC $OPTS -e "ssh -i $PR_KEY" $RC $REM_USER_HOST:$REM_RC_PATH 2>&1 | $TEE $LOG_FILE

else
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then 
		echo "[INFO]  : running from interactive terminal"
		echo "[DEBUG] : exec \\ $TIME $RSYNC $OPTS -e \"ssh -i $PR_KEY\" $RC $REM_USER_HOST:$REM_RC_PATH 2>&1 | $TEE $LOG_FILE"
	fi
	$TIME $RSYNC $OPTS -e "ssh -i $PR_KEY" $RC $REM_USER_HOST:$REM_RC_PATH 2>&1 | $TEE $LOG_FILE

fi

RET=`grep "rsync error:" $LOG_FILE`

# check if error
if [ -n "$RET" ]; then
	mail_err_array=()
	echo "Seems there was an error: checking output;"
	for i in "${GREP_ERROR_STR[@]}"
	do
		msg=`grep "$i" $LOG_FILE`
		
		#append to mail array
		mail_err_array+=("$msg")

		# echo msg to stdout
		printf "$msg\n"
		
		# echo to syslog
		logger "$SCRIPT_NAME: $msg"

	done

	#prepare msg
	msg="${mail_err_array[@]}
	
-------------------------------------------------------------------
see the logfile located in $LOG_FILE or check syslog
"

	# email error to me
	$MAILER -f $FROM -t $TO -s "$SUBJ" -b "$msg"
	exit $EXIT_ERR_GREP;

else
	exit $EXIT_ERR_SUCCESS;
fi
