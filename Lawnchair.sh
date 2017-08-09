#!/bin/bash

url='https://labs.xda-developers.com/store/app/download/ch.deletescape.lawnchair'

#CUR_DIR=`pwd`
DOWN_PATH='Lawnchair/'

CHECK=`wget -q --tries=10 --timeout=20 --spider http://google.com`

if [[ $? -eq 0 ]]; then
	echo "Grabbing the latest version of Lawnchair"
	DOWN=`wget -O $DOWN_PATH/Lawnchair.apk $url`
	break
else
	echo "Looks like you aren't connected to the Internet"
	if [[ -f $DOWN_PATH/Lawnchair.apk ]] ; then
		echo "An old version of Lawnchair exists, using it for now."
	else
		echo "Nothing found! Lawncahir won't be available in this build!"
        fi
fi