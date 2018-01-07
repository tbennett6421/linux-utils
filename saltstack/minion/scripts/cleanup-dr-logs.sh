#!/usr/bin/env bash

# check for root
if [ "$EUID" -ne 0 ]; then 
    echo "This program must be run as a privileged user"
    exit 1
fi

cd /var/log/dr
find . -maxdepth 1 -type f | sort -r | sed -e '1,30d' | xargs rm -f
