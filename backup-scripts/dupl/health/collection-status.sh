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

RED='\033[1;31m'
NC='\033[0m'

################################################################################
### Begin configurable options;
### set options using $BOOL_TRUE, $BOOL_FALSE, 'stringvalues' or integer
d_target='/dr/servers'                  ## the base server backup directory
B_MAIL=$BOOL_TRUE                       ## should this program use email subsystem

########################################################################
### Begin Constants and Definitions
########################################################################
EXIT_ERR_SUCCESS=0
EXIT_ERR_USAGE=1

## see your relevant man pages or test using $?
RTC_TTY_IS_TERMINAL=0

## get program paths
DUPLICITY=`which duplicity`
CAT=`which cat`
TEE=`which tee`
TTY=`which tty`

`$TTY -s`                   ## exec tty -s and capture exit status,
TTY_SETTING=$?;             ## this will let us detect if running interactively

SCRIPT_NAME=`basename "$0"`

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
    
    -a|--all             show info on all backups
    -t|--target <name>   show info on a named backup
    -l|--list            list all backup targets
    -d|--debug           enable debugging output
    -h|--help            prints this help menu.
EOF
exit $EXIT_ERR_USAGE
}
    
function do_return_target(){
    local var=`echo $1 | sed "s~$d_target/~~"`
    echo "$var"
}

function do_print_list(){
  arr=("$@")
  count=0
  for i in "${arr[@]}"; do
    var=$(do_return_target $i)
    l=${#var}
    if [ "$l" -gt "$count" ]; then count=$l; fi
  done
  for i in "${arr[@]}"; do
    var=$(do_return_target $i)
    printf "${RED}%-${count}s${NC} : %s\n" "$var" "$i"
  done
}
function do_print_chain(){
    DUPL_STR="collection-status -v4 "
    DUPL_STR+="file://$1"
    echo '-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-_-'
    var=$(do_return_target $i)
    echo -e "Server: ${RED}$var${NC}"
	eval $DUPLICITY $DUPL_STR
}
########################################################################
### Begin program execution and logic
########################################################################

###### CLI Parsing ######
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -a|--all)
    F_ALL="true"
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
    -t|--target)
        F_TARGET="true"
        if [ -z "$2" ]; then
            usage
        else
            F_TARGET_VAL=$2; 
        fi
    shift 2
    ;;
    -l|--list)
    F_LIST="true"
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

## BEGIN
## store the directories in an array
## as we will be cd'ing a lot
declare -a arr
eoa=0;

cd $d_target;
## iterate over each server directory
for d in */; do
	## build the running-config folder
	tar_dir="$d_target""/""$d"
	## append target into the array
	arr[$eoa]=$tar_dir
	let "eoa++"
done

if [ "$F_LIST" ]; then
  do_print_list "${arr[@]}"
fi

if [ "$F_TARGET" ]; then
    for i in "${arr[@]}"; do
        var=$(do_return_target $i)
        if [ "$var" == "$F_TARGET_VAL" ]; then
            do_print_chain $i
        fi
    done
fi

if [ "$F_ALL" ]; then
  for i in "${arr[@]}"; do
    do_print_chain $i
  done
fi
