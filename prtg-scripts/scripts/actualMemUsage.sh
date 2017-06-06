#!/bin/bash
ret=`free -m | grep Mem | awk '{print $3/$2 * 100.0}'`
hret=`printf "%.*f\n" 2 $ret`
echo "0:$ret:$hret% Used"
