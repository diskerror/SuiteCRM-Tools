#!/bin/bash -x

# A script for creating a clean copy of a SuiteCRM instance for
# a more normalized way of comparing directory structures and files.

# usage
# ./make_clean.sh ~/PhpStormProjects/MySuiteCRM/

# This script is not intended for usage "as is".
# It will likely need custommization for your system.
# Written for use on Mac OS 12.6 Monterey with
# rsync  version 3.2.7  protocol version 31

if [[ ! -d "$HOME" ]]; then
    echo 'HOME environment variable bad'
    exit 1
fi

if [[ ! -d "$1" ]]; then
    echo 'directory does not exist'
    exit 1
fi

case "$1" in
    */)
        declare -r INPUT_DIR="$1"
        ;;
    *)
        declare -r INPUT_DIR="${1}/"
        ;;

esac

declare -r CLEAN_DIR="${HOME}/Desktop/"$(basename "$INPUT_DIR")'_clean/'

if [[ ! -d "$CLEAN_DIR" ]]; then
    mkdir "$CLEAN_DIR"
fi

# Copy only PHP files.
rsync -rtm --info=progress2 --del \
    --exclude='/cache/***' \
    --exclude='/upload/***' \
    --exclude='/custom/history/***' \
    --include='*/' \
    --include='*.php' \
    --exclude='/**' \
    "${INPUT_DIR}" "${CLEAN_DIR}"

# Remove lines with "// created: " and timestamp. Remove space[s] at end of first line.
LC_ALL=C find "${CLEAN_DIR}" -type f \
    -exec sed -E -i '' -e '/^[ \t]*\/\/ +created: +20.+$/d' {} \; \
    -exec sed -E -i '' -e 's/^<\?php[ \t]+$/<?php/' {} \;

# Remove lines with only white characters and comments in these files.
LC_ALL=C find -E "${CLEAN_DIR}" \
    -iregex '.*\.ext\.php|.*\.lang\.php|.*/vardefs\.php|.*/relationships\.php|.*/manifest\.php|.*/config\.php' \
    -exec sed -E -i '' -e '/^([ \t]*|[ \t]*\/\/.*|[ \t]*\/\*.*|[ \t]*\*.*)$/d' {} \;
