#!/bin/bash

# Script to synchronize local development version of SuiteCRM 7 to a local testing
#   server and to a live server. This attempts to handle only the necessary files for
#   code maintenance and development, and ignoring bulky data files and temporary
#   upload files.

# WARNING: Managed files, such as those ending with '.php', which are deleted locally
#   will also be deleted on all remote servers when synchronizing.

# For MacOS, Linux, BSD due to shell expansion. Using:
# rsync  version 3.2.7  protocol version 31
# Copyright (C) 1996-2022 by Andrew Tridgell, Wayne Davison, and others.
# Web site: https://rsync.samba.org/

# Find and format a list of files with sizes in the current directory and all subdirectories.
#> find . -type f -and \( -name '.*' -or -name '*' \) -print0 | wc -c --files0-from=- | sed 's# \./#\t#'`

# Servers have been configured with SuiteCRM files with owner setting 'chown www-data:www-data'
#   so that SuiteCRM can write to it's own files and directories.

# Set command and universal options.
declare -r RSYNC='rsync -rlDue ssh'
declare -r NL=$'\n'

# Look for config file in the user's home directory.
declare -r CONFIG_FILE='.suite_rsync.cfg'

# Set constants and variables. Settings should be in project config file.
declare LIVE_SERVER='10.10.10.17'
declare LOCAL_SERVER='192.168.56.5'

# Both paths must have a trailing slash.
declare LIVE_SERVER_PATH='/var/www/html/'
declare LOCAL_SERVER_PATH='/var/www/html/'

declare FILTERS=''
declare ADD_OPTIONS=''
declare SUBPATH=''
declare SUBPATH_FILTER="${NL}+ /**${NL}"
declare CONT='yes'

# Common exclude filters.
declare -r COMMON_EXCLUDE='
suite_rsync.sh
*suite_rsync.cfg*
/.idea/***
/.editorconfig
.DS_Store
.git*
.git*/**
/.well-known/***
*.log
*.csv'

# Exclude filters only needed with connections to live host.
declare -r LIVE_EXCLUDE='
*.zip
*[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]
IMPORT_*[0-9]
sugarcrm_old.sql
09888'

# Do not push these back to either server.
declare -r TO_LIVE_SERVER_EXCLUDE='
*~
/cache/***
/custom/history/***
/upload/***
/upload:/***
/vendor/***'

usage () {
    echo "Usage: $(basename $0) [-dhis] local-dev-directory livetodev|devtolive|devtolocal|localtodev [subpath only]"
}

##########################################################################################
# MAIN

# Handle options.
while getopts "dhis" opt
do
    case ${opt} in
        d)
            ADD_OPTIONS="${ADD_OPTIONS} --dry-run --debug=filter1"
            shift "$((OPTIND-1))"
            ;;

        h)
            usage
            exit 0
            ;;

        i)
            ADD_OPTIONS="${ADD_OPTIONS} --dry-run --itemize-changes"
            shift "$((OPTIND-1))"
            ;;

        s)
            ADD_OPTIONS="${ADD_OPTIONS} --info=progress2,stats2"
            shift "$((OPTIND-1))"
            ;;

        \?)
            usage
            exit 1
            ;;
    esac
done

if [[ $# -gt 3 || $# -lt 2 ]]
then
    usage
    exit 1
fi

# Expand relative paths for clarity. Path must have trailing slash.
declare -r DEV_PATH=$(realpath "$1")"/"


# Read defaults from config file. They will overwrite corresponding variables.
if [[ -f "${DEV_PATH}${CONFIG_FILE}" ]]
then
    source "$CONFIG_FILE"
fi

if [[ $# -eq 3 ]]
then
    case $3 in
        /*)
            SUBPATH_FILTER="${NL}+ ${3}/***${NL}/**${NL}"
            ;;
            
        *)
            SUBPATH_FILTER="${NL}+ /${3}/***${NL}/**${NL}"
            ;;
    esac
    SUBPATH="${3}"
fi

if [ ! -d "${DEV_PATH}${SUBPATH}" ]
then
    echo "\"${DEV_PATH}${SUBPATH}\" does not exist or is not a directory."
    exit 1
fi


case $2 in
    livetodev)
        FILTERS="${COMMON_EXCLUDE}${LIVE_EXCLUDE}${SUBPATH_FILTER}"
        CMD="$RSYNC ${ADD_OPTIONS} --bwlimit=2m --exclude-from=- $LIVE_SERVER:$LIVE_SERVER_PATH $DEV_PATH"
        ;;

    devtolive)
        FILTERS="${TO_LIVE_SERVER_EXCLUDE}${COMMON_EXCLUDE}${LIVE_EXCLUDE}${SUBPATH_FILTER}"
        CMD="$RSYNC ${ADD_OPTIONS} --bwlimit=2m --exclude-from=- $DEV_PATH $LIVE_SERVER:$LIVE_SERVER_PATH"
        ;;

    devtolocal)
        FILTERS="${COMMON_EXCLUDE}${SUBPATH_FILTER}"
        CMD="$RSYNC ${ADD_OPTIONS} --exclude-from=- $DEV_PATH $LOCAL_SERVER:$LOCAL_SERVER_PATH"
        ;;

    localtodev)
        FILTERS="${COMMON_EXCLUDE}${SUBPATH_FILTER}"
        CMD="$RSYNC ${ADD_OPTIONS} --exclude-from=- $LOCAL_SERVER:$LOCAL_SERVER_PATH $DEV_PATH"
        ;;

    *)
        usage
        exit 1
        ;;
esac

# Always print command to make sure.
echo "${FILTERS}"
echo "${CMD}"

read -p "${NL}Continue? [Y|n]: " cont
if [[ ! -z $cont ]]; then
    CONT=$cont
fi

case $CONT in
    [Yy]*)
        echo "${FILTERS}" | ${CMD}
        ;;

    *)
        echo 'Canceled.'
        ;;
esac

exit 0
