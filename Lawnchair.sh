#!/bin/bash

url='https://labs.xda-developers.com/store/app/download/ch.deletescape.lawnchair'

#CUR_DIR=`pwd`
DOWN_PATH='Lawnchair/'

# Package manager check to install 'wget'
declare -A osInfo;
osInfo[/etc/redhat-release]=yum
osInfo[/etc/pacman.conf]=pacman
osInfo[/etc/debian_version]=apt-get

if which wget > /dev/null 2> /dev/null 
then
	echo "wget package found..."
else
	echo "wget package not found. Trying to install..."
	for f in ${!osInfo[@]}
	do
		if [[ -f $f ]]; then
			echo Package manager: ${osInfo[$f]}
			TEMP=${osInfo[$f]}
		fi
	done

	case "$TEMP" in
		"yum")
			`sudo yum install wget`
		;;
		"apt-get")
			`sudo apt-get intall wget`
		;;
		"pacman")
			`sudo pacman -S wget`
		;;
		*)
			echo "Unknow Distribution! 'wget' couldn't be installed. Please install it manually"
		;;
	esac
fi
		
CONNECTION_CHECK=`wget -q --tries=10 --timeout=20 --spider http://google.com`

if [[ $? -eq 0 ]]; then
	echo "Grabbing the latest version of Lawnchair"
	DOWN=`wget -q -O $DOWN_PATH/Lawnchair.apk $url`
else
	echo "Looks like you aren't connected to the Internet"
	if [[ -f $DOWN_PATH/Lawnchair.apk ]] ; then
		echo "An old version of Lawnchair exists, using it for now."
	else
		echo "Nothing found! Lawncahir won't be available in this build!"
        fi
fi