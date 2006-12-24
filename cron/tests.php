<?php
/*
  +----------------------------------------------------------------------+
  | PHP QA GCOV Website                                                  |
  +----------------------------------------------------------------------+
  | Copyright (c) 2005-2006 The PHP Group                                |
  +----------------------------------------------------------------------+
  | This source file is subject to version 3.01 of the PHP license,      |
  | that is bundled with this package in the file LICENSE, and is        |
  | available through the world-wide-web at the following url:           |
  | http://www.php.net/license/3_01.txt                                  |
  | If you did not receive a copy of the PHP license and are unable to   |
  | obtain it through the world-wide-web, please send a note to          |
  | license@php.net so we can mail you a copy immediately.               |
  +----------------------------------------------------------------------+
  | Author: Daniel Pronych <pronych@php.net>                             |
  |         Nuno Lopes <nlopess@php.net>                                 |
  +----------------------------------------------------------------------+
*/

/* $Id$ */

// Tests generation file
// $data: contains the contents of $tmpdir/php_test.log

$fail_tests = array();
$skip_tests = array();
$tests_re = '/(?P<status>FAIL|PASS|SKIP)(?::(?P<testtype>[a-z|A-Z]))? (?P<title>.+) \[(?P<file>[^\]]+)\](?: reason: (?P<reason>.+))?/';

preg_match_all($tests_re, $data, $tests, PREG_SET_ORDER);

foreach ($tests as $test) {

	$status = $test['status']; // FAIL, PASS or SKIP
	$title  = $test['title'];
	$reason = isset($test['reason']) ? $test['reason'] : '';

	// Note: that the following period is maintained
	$base = "$phpdir/".substr($test['file'],0,-4);

	$report_file = $base;

	if (isset($test['testtype']) && strtolower($test['testtype']) == 'u') {
		$testtype = 'Unicode';
		$report_file .= 'u.';
	} else {
		$testtype = 'Native';
	}

	// Failed tests provide more content then passed tests
	if ($status === 'FAIL') {
		$difference = @file_get_contents($report_file.'diff');
		$expected   = @file_get_contents($report_file.'exp');
		$output     = @file_get_contents($report_file.'out');
		$script     = @file_get_contents($base.'php');

		++$totalnumfailures;

		$fail_tests[$test['file']] = array($testtype, $title, $difference, $expected, $output, $script);
	
	} elseif ($status === 'SKIP') {
		$skip = @file_get_contents($report_file.'skip.php');

		$skip_tests[$test['file']] = array($skip, $reason);
	}
}


// sort by filename
ksort($skip_tests);
ksort($fail_tests);

// now write the raw data to thw www dir
file_put_contents("$outdir/skip.inc", serialize($skip_tests));
file_put_contents("$outdir/fail.inc", serialize($fail_tests));
