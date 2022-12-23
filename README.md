## SuiteCRM-Tools

A set of bash scripts to help manage a SuiteCRM instance.

### suite_rsync.sh

A wrapper for rsync to ignore and protect business documents and data files from
being included in syncing. Cache directory files are pulled from the
servers for debugging but not pushed back.

The script will look for a configuration file named ".suite_rsync.cfg" in the
root of the desired project directory.

### make_clean.sh

A script for creating a clean copy of a SuiteCRM instance for
a more normalized way of comparing directory structures and files.

## ~/.*profile

I've added these lines to my ".zprofile" file:
~~~
alias suite_rsync=~/Documents/Diskerror/SuiteCRM-Tools/suite_rsync.sh
alias make_clean=~/Documents/Diskerror/SuiteCRM-Tools/make_clean.sh
~~~
