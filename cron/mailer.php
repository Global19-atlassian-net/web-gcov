<?php

require_once 'lib/phpmailer/class.phpmailer.php';

class MyMailer extends PHPMailer
{

        var $CharSet = 'iso-8859-1';
	var $ContentType = 'text/html';
/*
	var $From     	= 'someaddress@example.com';
	var $FromName 	= 'Some Address';
*/
	var $From = 'some.address@example.com';
	var $FromName = 'Some Address';

	var $Host = 'localhost';

	var $Mailer = 'smtp';		// Alternative to IsSMTP()

	var $priority = 3;

	var $SMTPAuth = false;

	var $WordWrap = 75;

	function MyMailer()
	{
		// Handles SMTPAuth (if enabled)
		if($SMTPAuth == true)
		{
			$Username = 'username';
			$Password = 'password';
		}

		$From = 'pronych@php.net';
		$FromName = 'Daniel Pronych';

	}

}
