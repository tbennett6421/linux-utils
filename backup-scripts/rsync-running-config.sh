#!/usr/bin/env bash
##
## Author:        Tyler Bennett
## Email:         tbennett6421@gmail.com
## Date:          2017-11-26
## Usage:         rsync-running-config.sh
## Description:   Backup a system using duplicity
BOOL_TRUE=1
BOOL_FALSE=0

########################################################################
### Begin configurable options;
### set options using $BOOL_TRUE, $BOOL_FALSE, 'stringvalues' or integer
########################################################################
SSH_PASSWORD='setme'
GPG_PASSWORD='setme'
LOG_DIR='/var/log/dr'
B_DEBUG=$BOOL_TRUE          # should this program be verbose
B_MAIL=$BOOL_TRUE           # should this program use email subsystem
PING_COUNT=3                # number of ICMP packets to send to remote
HASROLE_LAMP=$BOOL_FALSE	# Has Apache, MySQL, PHP?
HASROLE_ZFS=$BOOL_FALSE 	# Has ZFS and ZPools?
