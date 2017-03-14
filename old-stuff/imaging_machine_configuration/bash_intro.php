<?php

	$warnStyle = array(
		'foreground'	=>	'white',
		'background'	=>	'red',
		'style'		=>	'bold'
	);

	$devStyle = array(
		'foreground'	=>	'white',
		'background'	=>	'blue',
		'style'		=>	'bold'
	);	
	
	$optionStyle = array(
		'foreground'	=>	'white',
		'background'	=>	'green',
		'style'		=>	'bold'
	);

	$keyword = "cyan";
	$comment = "blue";



/////////////////////////////////////////////////////////////////

	require 'CLICommander.php';
	$cli = new CLICommander();
	$cli->Clear();
    
    	//get commands to run
    	$path = 'sudo /usr/local/bin/uuid-to-dev';
    	$output = exec($path);

	//echo system header
	$cli->Write("# The system is mounted on ");
	$cli->Write("$output".PHP_EOL, $devStyle);
	$cli->WriteLine("# DO NOT TOUCH THIS DEVICE!!!", $warnStyle);
	$cli->Write(PHP_EOL);

	###############################################
	$cli->Write("# ", $comment);
	$cli->Write("dcfldd", $keyword);
	$cli->Write(" is an improved version of ", $comment);
	$cli->Write("dd", $keyword);
	$cli->Write(" with support for multiple outputs,", $comment);
	$cli->Write(PHP_EOL);
	$cli->WriteLine("# on-the-fly hashing, and status output", $comment);
	$cli->Write(PHP_EOL);	
	###############################################



	###############################################
	$cli->Write("# Standard error checking ", $comment);
	$cli->Write("dd", $keyword);
	$cli->Write(", be sure to run ", $comment);
	$cli->Write("sync", $keyword);
	$cli->WriteLine(" to ensure file buffers are flushed", $comment);

	$cli->Write("dcfldd", $keyword);
	$cli->Write(" if=");
	$cli->Write("/dev/src", $devStyle);
	$cli->Write(" of=");
	$cli->Write("/dev/tar", $devStyle);
	$cli->Write(" bs=");
	$cli->Write("4096", $devStyle);
	$cli->Write(" conv=");
	$cli->Write("noerror,notrunc,sync", $optionStyle);
	$cli->Write(PHP_EOL);
	$cli->WriteLine("sync", $keyword);
	$cli->Write(PHP_EOL);
	###############################################


	###############################################
	$cli->Write("# Standard drive wipe with ", $comment);
	$cli->Write("dd", $keyword);
	$cli->Write(PHP_EOL);

	$cli->Write("dcfldd", $keyword);
	$cli->Write(" pattern=");
	$cli->Write("00", $optionStyle);
	$cli->Write(" of=");
	$cli->Write("/dev/tar", $devStyle);
	$cli->Write(" bs=");
	$cli->Write("4096", $devStyle);
	$cli->Write(PHP_EOL);
	$cli->Write("dcfldd", $keyword);
	$cli->Write(" pattern=");
	$cli->Write("FF", $optionStyle);
	$cli->Write(" of=");
	$cli->Write("/dev/tar", $devStyle);
	$cli->Write(" bs=");
	$cli->Write("4096", $devStyle);
	$cli->Write(PHP_EOL);
	$cli->Write(PHP_EOL);
	###############################################






//////////////////////////////////////
	###############################################
	$cli->Write("# Standard ", $comment);
	$cli->Write("dd", $keyword);	
	$cli->Write(" with ", $comment);
	$cli->Write("gzip", $keyword);
	$cli->Write(" compression", $comment);
	$cli->Write(PHP_EOL);

	$cli->Write("dcfldd", $keyword);
	$cli->Write(" if=");
	$cli->Write("/dev/src", $devStyle);
	$cli->Write(" bs=");
	$cli->Write("4096", $devStyle);
	$cli->Write(" conv=");
	$cli->Write("noerror,notrunc,sync", $optionStyle);
	$cli->Write(" | ");
	$cli->Write("gzip", $keyword);
	$cli->Write(" -c > src.img.gz");
	$cli->Write(PHP_EOL);

	$cli->Write("sudo gunzip", $keyword);
	$cli->Write(" -c src.img.gz | ");
	$cli->Write("sudo dcfldd", $keyword);
	$cli->Write(" of=");
	$cli->Write("/dev/tar", $devStyle);
	$cli->Write(" bs=");
	$cli->Write("4096", $devStyle);
	$cli->Write(" conv=");
	$cli->Write("noerror,notrunc,sync", $optionStyle);
	$cli->Write(PHP_EOL);
	$cli->Write(PHP_EOL);
	###############################################



    
    /*    

	dd of=/dev/src conv=sync,noerror bs=4096
	
	# MBR backup. 446 bytes will do your boot code, 512 will include partition table
	# only use 512 with indentically partitioned drives
	dd if=/dev/sda of=/dev/sdb bs=446 count=1
	dd if=/dev/sda of=/dev/sdb bs=512 count=1
    */
