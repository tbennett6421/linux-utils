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

########################################################################
### Begin configurable options;
### set options using $BOOL_TRUE, $BOOL_FALSE, 'stringvalues' or integer
########################################################################
SSH_PASSWORD='setme'   ##!!
GPG_PASSWORD='setme'   ##!!
LOG_DIR='/var/log/dr'
B_DEBUG=$BOOL_TRUE          ## should this program be verbose
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
EXIT_ERR_SUDO=1
EXIT_ERR_PING=2
EXIT_ERR_SSH=3
##@@EXIT_ERR_GREP=4
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

`$TTY -s`                   ## exec tty -s and capture exit status,
TTY_SETTING=$?;             ## this will let us detect if running interactively

##@@OPTS="-avhP --stats --relative --ignore-missing-args"		
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

function icmpreq(){
	if [ $B_DEBUG -eq $BOOL_TRUE ]; then
		echo "[DEBUG] : $PING -q -c $PING_COUNT $1 > /dev/null 2>&1"
	fi
    return `$PING -q -c $PING_COUNT $1 > /dev/null 2>&1`
}

########################################################################
### Begin program execution and logic
########################################################################

## Check for superuser, required to access restricted files for backup
if [ "$EUID" -ne 0 ]; then 
	echo "This program must be run as a privileged user"
  	exit $EXIT_ERR_SUDO
fi

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

DUPL_BKUP_STR="duplicity "
DUPL_BKUP_STR+="${DUPL_BKUP[*]}"        ## print entire array on one-line
DUPL_BKUP_STR+=" --exclude '**' / "     ## space, exclude option
##@@DUPL_BKUP_STR+="sftp://tbennett@dr/dr-test -v4 --ssh-askpass"
