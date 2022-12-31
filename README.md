# SuiteCRM-Tools

A set of scripts to help manage a SuiteCRM instance.

## suite_rsync

A wrapper for rsync to ignore and protect business documents and data files from
being included in syncing. Cache directory files are pulled from the
servers for debugging but not pushed back. There are two versions.

### suite_rsync.sh

The script will look for a configuration file named ".suite_rsync.cfg" in the
root of the desired project directory. This script requires that the first argument
be a path to the dev working directory.

### suite_rsync.php

The script will look for a configuration file named ".suite_rsync.ini" in the
root of the desired project directory. If the path to the local working directory is
omitted then the current working directory is used.

## make_clean.sh

A script for creating a clean copy of a SuiteCRM instance for
a more normalized way of comparing directory structures and files.

## ~/.*profile

I've added these lines to my  ".zprofile" file (MacOS Ventura):
~~~
alias srsync=~/Documents/Diskerror/SuiteCRM-Tools/suite_rsync.php
alias mcl=~/Documents/Diskerror/SuiteCRM-Tools/make_clean.sh
~~~
