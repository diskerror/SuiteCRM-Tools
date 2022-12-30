#!php
<?php
//	Script to synchronize local development version of SuiteCRM 7 to a local testing
//	  server and to a live server. This attempts to handle only the necessary files for
//	  code maintenance and development, and ignoring bulky data files and temporary
//	  upload files.

//	For MacOS, Linux, BSD due to shell expansion. Using:
//	rsync  version 3.2.7  protocol version 31
//	Copyright (C) 1996-2022 by Andrew Tridgell, Wayne Davison, and others.
//	Web site: https://rsync.samba.org/

//	Find and format a list of files with sizes in the current directory and all subdirectories.
//	> find . -type f -and \( -name '.*' -or -name '*' \) -print0 | wc -c --files0-from=- | sed 's# \./#\t#'`

//	Servers have been configured with SuiteCRM files with owner setting 'chown www-data:www-data'
//	  so that SuiteCRM can write to it's own files and directories.

//	 Set command and universal options.
define('RSYNC', 'rsync -rlDume ssh');
define('NL', "\n"); //	 Not PHP_EOL.

//	 Look for config file in the user's home directory.
define('CONFIG_FILE', '.suite_rsync.ini');

//	 Set constants and variables. Settings should be in project ini file.
//	 Both of these can be empty and correnponding path can be elsewhere on the local workstation.
$liveServer  = '10.10.10.17';
$localServer = '192.168.56.5';

//	 Both paths must have a trailing slash.
$liveServerPath  = '/var/www/html/';
$localServerPath = '/var/www/html/';

$devPath       = '';
$commandVerb   = '';
$filters       = '';
$addOptions    = '';
$subpath       = '';
$subpathFilter = NL . '+ /**' . NL;
$cont          = 'yes';

//	Common exclude filters.
define('COMMON_EXCLUDE', <<<COMMON_EXCLUDE
*suite_rsync*
/.idea/***
/.editorconfig
.DS_Store
.git*
.git*/**
/.well-known/***
*.log
*.csv
COMMON_EXCLUDE
);

//	Exclude filters only needed with connections to live host.
define('LIVE_EXCLUDE', <<<LIVE_EXCLUDE
*.zip
*[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]
IMPORT_*[0-9]
sugarcrm_old.sql
09888
LIVE_EXCLUDE
);

//	Do not push these back to live server.
define('TO_LIVE_EXCLUDE', <<<TO_LIVE_EXCLUDE
*~
/cache/***
/custom/history/***
/upload/***
/upload:/***
/vendor/***
TO_LIVE_EXCLUDE
);

define('USAGE',
	'Usage: ' . basename($argv[0]) . ' [-dhis] [local-dev-directory] livetodev|devtolive|devtolocal|localtodev [subpath only]' . NL);

////////////////////////////////////////////////////////////////////////////////////////////////////
//	MAIN

//	 Options must come before remaining parameters.
$ri   = 0;
$opts = getopt('dhis', [], $ri);

if (array_key_exists('d', $opts)) {
	$addOptions .= ' --dry-run --debug=filter1';
}

if (array_key_exists('h', $opts)) {
	fprintf(STDOUT, USAGE);
	exit;
}

if (array_key_exists('i', $opts)) {
	$addOptions .= ' --dry-run --itemize-changes';
}

if (array_key_exists('s', $opts)) {
	$addOptions .= ' --info=progress2,stats2';
}

$args = [$argv[0]];
for ($ri; $ri < $argc; ++$ri) {
	if (substr($argv[$ri], 0, 1) !== '-') {
		$args[] = $argv[$ri];
	}
}

switch (count($args)) {
	case 2:
		$devPath     = $_SERVER['PWD'] . '/';
		$commandVerb = $args[1];
		break;

	case 3:
		//	 Determine if it's "devpath verb" or "verb  subpath".
		$aOne = realpath($args[1]);
		if (is_dir($aOne)) {
			$devPath     = $aOne . '/';
			$commandVerb = $args[2];
		}
		else {
			$devPath     = $_SERVER['PWD'] . '/';
			$commandVerb = $args[1];
			$subpath     = $args[2];
		}
		break;

	case 4:
		$devPath     = realpath($args[1]) . '/';
		$commandVerb = $args[2];
		$subpath     = $args[3];
		break;

	default:
		fprintf(STDERR, 'Malformed arguments.' . NL);
		fprintf(STDERR, USAGE);
		exit(1);
}

//	 Remove leading subpath slash, if any.
if (substr($subpath, 0, 1) === '/') {
	$subpath = substr($subpath, 1);
}

if ($subpath !== '') {
	$subpathFilter = NL . "+ /${subpath}/***" . NL . '/**' . NL;
}

//	Read defaults from config file. They will overwrite corresponding variables.
if (file_exists($devPath . CONFIG_FILE)) {
	foreach (parse_ini_file($devPath . CONFIG_FILE, false, INI_SCANNER_TYPED) as $k => $v) {
		$$k = $v;
	}
}

if (!is_dir($devPath . $subpath)) {
	echo "\"${devPath}${SUBPATH}\" does not exist or is not a directory.";
	exit(1);
}

if ($liveServer !== '' && substr($liveServer, -1) !== ':') {
	$liveServer .= ':';
}

if ($localServer !== '' && substr($localServer, -1) !== ':') {
	$localServer .= ':';
}

switch ($commandVerb) {
	case 'livetodev';
		$filters = COMMON_EXCLUDE . LIVE_EXCLUDE . $subpathFilter;
		$cmd     = RSYNC . " $addOptions --bwlimit=2m --exclude-from=- $liveServer$liveServerPath $devPath";
		break;

	case 'devtolive';
		$filters = TO_LIVE_EXCLUDE . COMMON_EXCLUDE . LIVE_EXCLUDE . $subpathFilter;
		$cmd     = RSYNC . " $addOptions --bwlimit=2m --exclude-from=- $devPath $liveServer$liveServerPath";
		break;

	case 'devtolocal';
		$filters = COMMON_EXCLUDE . $subpathFilter;
		$cmd     = RSYNC . " $addOptions --exclude-from=- $devPath $localServer$localServerPath";
		break;

	case 'localtodev';
		$filters = COMMON_EXCLUDE . $subpathFilter;
		$cmd     = RSYNC . " $addOptions --exclude-from=- $localServer$localServerPath $devPath";
		break;

	default:
		fprintf(STDERR, 'Bad verb.' . NL);
		fprintf(STDERR, USAGE);
		exit(1);
}

//	Always print command to make sure.
echo $filters, NL;
echo $cmd, NL;

if ($rline = readline(NL . 'Continue? [Y|n]: ')) {
	$cont = $rline;
}

if (substr(strtolower($cont), 0, 1) === 'y') {
	passthru('echo "' . $filters . '" | ' . $cmd);
}
else{
	echo 'Canceled.';
}

exit;
