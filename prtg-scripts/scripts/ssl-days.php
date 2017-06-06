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

    # Fetch NotAfter=
    $cmd = "echo | openssl s_client -connect $param:443 2>/dev/null | openssl x509 -noout -dates | grep After";
    $output = shell_exec($cmd);

    # Massage dates
    $pos = strpos($output, '=');
    $output = substr($output, $pos+1);
    $future = new DateTime($output);
    $today  = new DateTime();

    # Get Days
    $interval = $today->diff($future);
    $days = $interval->format('%a');
    $str= "0:$days:$days days remaining";
    echo $str;
} else {
    echo "4:-1:Parameter '$param' not accepted";
}