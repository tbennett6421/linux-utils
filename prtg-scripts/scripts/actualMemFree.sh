#!/bin/bash
ret=`free -m | grep Mem | awk '{print $7/$2 * 100.0}'`
hret=`printf "%.*f\n" 2 $ret`
echo "0:$ret:$hret% Free"
