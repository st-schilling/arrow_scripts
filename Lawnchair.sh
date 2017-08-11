#!/bin/bash

url='https://labs.xda-developers.com/store/app/download/ch.deletescape.lawnchair'

CUR_DIR=`pwd`
DOWN_PATH="$CUR_DIR/dot_scripts/Lawnchair"

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
		
wget -q --tries=10 --timeout=20 --spider http://google.com

if [[ $? -eq 0 ]]; then
	if [[ -f $DOWN_PATH/Lawnchair.apk ]] ; then
		if [[ $(find "$DOWN_PATH/Lawnchair.apk" -mtime +1 -print) ]]; then
			echo "We already have the latest version of Lawnchair"
	fi
		else
			echo "Grabbing the latest version of Lawnchair"
			wget -q --show-progress -O $DOWN_PATH/Lawnchair.apk $url
		fi
else
	echo "Looks like you aren't connected to the Internet"
	if [[ -f $DOWN_PATH/Lawnchair.apk ]] ; then
		echo "An old version of Lawnchair exists, using it for now."
	else
		echo "Nothing found! Lawncahir won't be available in this build!"
        fi
fi