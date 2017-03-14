#!/bin/bash
#
# Tyler Bennett <tbennett6421@gmail.com>
# 2016-01-09
#
# This script will shutdown/reboot the devices passed to it via the command line
#

# constants
SCRIPT_NAME=`basename "$0"`
EXIT_ERR_SUCCESS=0
EXIT_ERR_USAGE=1
EXIT_ERR_PINGERR=2
PING_ISUP=0
PING_ISDOWN=1
PING_CONF=3
WAIT_SECS=5

vms=("10.1.1.2" "10.1.1.4" "10.1.1.5")
# add desktop clients
pms=("10.1.1.3")
# do vms, followed by all desktop clients, then all servers, then yourself
all=("10.1.1.2" "10.1.1.4" "10.1.1.5" "10.1.1.3" "10.1.1.1")
PING=`which ping`
SLEEP=`which sleep`

# function definitions
function usage(){
	printf "$SCRIPT_NAME\n";
	printf "Usage: -o [shutdown|reboot] -t [vms|pms|all] \n";
	printf " -h, --help               print usage menu. i.e this message\n";
	printf " -o, --opertation         operation: what to do\n";
	printf " -t, --targets            operation: who to target\n";
	printf "\n";
	exit $EXIT_ERR_USAGE;
}

function icmpreq(){
    $PING -q -c $PING_CONF $1 > /dev/null 2>&1
    if [ "$?" -eq $PING_ISUP ]; then
        return $PING_ISUP;
    fi
    if [ "$?" -eq $PING_ISDOWN ]; then
        return $PING_ISDOWN;
    fi
    # if you got this far and don't get 1 or 0, bail out
    printf "ping gave exit code $?\n"
    printf "you got to do shit on your own\n"
    exit $EXIT_ERR_PINGERR
}

function goingDown(){
# variable expansion
# see @http://unix.stackexchange.com/questions/60584/how-to-use-a-variable-as-part-of-an-array-name
eval ARR=\${$1[@]}
	for i in "${ARR[@]}"
	do
		ret=icmpreq $i
		if [ $ret -eq $PING_ISUP ] ; then
			echo "waiting: $WAIT_SECS";
			$SLEEP $WAIT_SECS
			echo "ssh $i 'sudo shutdown $OP now'"
			ssh $i "sudo shutdown $OP now" > /dev/null 2>&1
		else
			printf "$i is not responding to ICMP echo requests: seems to be down\n";
		fi
	done
}

######### MAIN BEGIN START ##########
# deal with people who enter too many arguments
if [[ "$#" -gt 4 ]]; then
	usage
fi

# parse the arguments
while [[ $# > 0 ]]
do
key="$1"

case $key in
    -h|--help)
    HELP=true
    ;;
    -o|--operation)
    if [[ "$2" == "shutdown" ||  "$2" == "reboot" ]]; then
    	OPERATION="$2"
	fi
    shift # past argument
    ;;
    -t|--targets)
    if [[ "$2" == "vms" || "$2" == "pms" || "$2" == "all" ]]; then
    	TARGETS="$2"
	fi
    shift # past argument
    ;;
    *)
            # unknown option
    ;;
esac
shift # past argument or value
done

# check for help
if [ "${HELP}" == true ]; then
	usage
fi

# check if both op and target are filled in
if [ -z "${OPERATION}" ]; then
	usage
fi

if [ -z "${TARGETS}" ]; then
	usage
fi

# set stuff for our commands based on arguments
if [ "${OPERATION}" == "shutdown" ]; then
	OP="-h"
fi

if [ "${OPERATION}" == "reboot" ]; then
	OP="-r"
fi

goingDown ${TARGETS}
exit $EXIT_ERR_SUCCESS