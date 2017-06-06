#!/usr/bin/php
<?php

if($argc !== 2){
    echo "4:-1:Failed to parse parameters";
    die;
}

$domains = array(
    "shimmie.nsecure.me",
    "cloud.nsecure.me",
    "pfsense.nsecure.me",
);

#fetch param
$param = $argv[1];
if(in_array($param, $domains, TRUE) === true){


    $cmd = 'curl -so /dev/null -w \'%{time_total}\' https://'.$param;
    $output = shell_exec($cmd);
    $str= "0:$output:$output milliseconds";
    echo $str;
} else {
    echo "4:-1:Parameter '$param' not accepted";
}