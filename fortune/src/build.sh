#!/usr/bin/env bash

shopt -s nullglob
arrayOfFiles=(*.txt)
array=("${arrayOfFiles[@]%.*}")

exists=0
D2U=`command -v dos2unix >/dev/null 2>&1`
ret=$?

if [ $ret -eq $exists ]; then
    dos2unix *.txt
fi

for i in "${array[@]}"
do
   cp "$i.txt" "$i"
   strfile -c % "$i"
done
