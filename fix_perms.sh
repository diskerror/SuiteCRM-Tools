#!/usr/bin/bash

# Set SuiteCRM desired permissions for all files and directories.
# SuiteCRM wants them this way. I consider this unsafe.

if [[ "root" != $USER ]]
then
	echo "must be root"
	exit
fi

# If not empty.
if [[ -n "${1}" ]]
then
    if [[ ! -d "${1}" ]]
    then
        echo "input directory does not exist"
        exit
    fi
    
    cd "${1}"
fi

echo 'fixing user and group'
chown -R www-data:www-data .

echo 'fixing files'
find . -type f ! -regex '.*/\..*' -print0 | xargs -0 -n 500 chmod 666

echo 'fixing directories'
find . -type d ! -regex '.*/\..*' -print0 | xargs -0 -n 500 chmod 777
chmod 2777 'cache'
#chmod 0750 'cache/themes'

# The "excludes" are used to skip obvious non-executable files.
# Set files where the first two characters make the she-bang (#!).
echo 'setting executables'
grep -rl --null \
  --exclude=\*.{asciidoc,base64,c,css,csv,dist,gif,htm,html,jpg,jpg,js,json,key,less,lib,log} \
  --exclude=\*.{map,md,md5,pack,pdf,png,pubkey,scss,svg,tpl,txt,TXT,xlf,xml,xsd,xyz,yml,zip} \
  --exclude={.\*,README,LICENSE,TODO,robo,VERSION} \
  --exclude=\*\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\]\[0-9a-f\] \
  --exclude-dir=upload/upgrades \
  --exclude-dir=cache -e '^#!' | xargs -0 sudo chmod a+x
