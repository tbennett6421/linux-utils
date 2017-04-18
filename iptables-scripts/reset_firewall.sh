#!/bin/bash

echo "starting firewall script"

IPTABLES="/sbin/iptables"

echo "flushing firewall rules"

## Attempt to Flush All Rules in Filter Table
$IPTABLES -F

echo "flushing built-in rules"
# Flush Built-in Rules


$IPTABLES -F INPUT
$IPTABLES -F OUTPUT
$IPTABLES -F FORWARD


## Set Default Policies
$IPTABLES -P INPUT ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD ACCEPT


