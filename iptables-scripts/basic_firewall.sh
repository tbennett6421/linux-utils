#!/bin/bash

IPTABLES="/sbin/iptables"

# flush all rules
$IPTABLES -F
$IPTABLES -F  INPUT
$IPTABLES -F OUTPUT
$IPTABLES -F FORWARD

## Set Default Policies
$IPTABLES -P INPUT DROP
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -P FORWARD DROP

# append a rule allowing all input on the loopback interface
$IPTABLES -A INPUT -i lo -j ACCEPT

# append a rule allowing input if related or established
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

# insert rules between comments for services
# you'll need rules for DNS, SSH, HTTP, HTTPS, SMTP from everywhere
$IPTABLES -A INPUT -p tcp -m tcp --dport 22 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m tcp --dport 25 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m tcp --dport 53 -j ACCEPT
$IPTABLES -A INPUT -p udp -m udp --dport 53 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
$IPTABLES -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
# end insert rules here

# Log input tcp packets
$IPTABLES -A INPUT -p tcp -j LOG

# Reject all other packets
$IPTABLES -A INPUT -j REJECT --reject-with icmp-host-prohibited


