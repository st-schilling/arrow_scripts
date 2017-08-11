#!/bin/sh

#LazyAss MagiskUpdate
CUR_DIR=`pwd`
APP_DIR="$CUR_DIR/vendor/dot/prebuilt/app/magisk"
ZIP_DIR="$CUR_DIR/vendor/dot/prebuilt/zips"
SCRIPTS_DIR="$CUR_DIR/dot_scripts"
orig_json='https://raw.githubusercontent.com/topjohnwu/MagiskManager/update/magisk_update.json'

# To avoid repo sync conflicts
if [[ -f $SCRIPTS_DIR/magisk_check.json ]]; then
	echo " " 
else
	# Ditch our local magisk_check.json to avoid it being 
	# replaced during repo syncs. So instead we grab and
	# store the orig on the first run of the script.
	wget -q -O $SCRIPTS_DIR/magisk_check.json $orig_json
fi

magisk_check=$(cat $SCRIPTS_DIR/magisk_check.json)
check_app_version=$(echo $magisk_check | jq --raw-output '.app.version')
check_zip_version=$(echo $magisk_check | jq --raw-output '.magisk.version')

magisk_json=$(curl -sk $orig_json)
app_version=$(echo $magisk_json | jq --raw-output '.app.version')
app_link=$(echo $magisk_json | jq --raw-output '.app.link')
zip_version=$(echo $magisk_json | jq --raw-output '.magisk.version')
zip_link=$(echo $magisk_json | jq --raw-output '.magisk.link')

if [ $check_app_version == $app_version ] && [ $check_zip_version == $zip_version ]; then
	echo "We already have the latest version Magisk"
else
	echo "Downloading Latest Magisk app"
	mv $APP_DIR/MagiskManager.apk $APP_DIR/MagiskManager.apk.bak
	wget --show-progress -O $APP_DIR/MagiskManager.apk $app_link 
	APP_DOWN_CHECK=$?

	echo " "

	echo "Downloading Latest Magisk zip"
	mv $ZIP_DIR/Magisk.zip $ZIP_DIR/Magisk.zip.bak
	wget -q --show-progress -O $ZIP_DIR/Magisk.zip $zip_link
	ZIP_DOWN_CHECK=$?

	if [ $APP_DOWN_CHECK == 0 ] && [ $ZIP_DOWN_CHECK == 0 ]; then
	# Replacing our magisk_check.json with the original json 
        # from github to cross check it later for updates and 
        # also to avoid re-downloading of the same versions again.
	wget -q -O $SCRIPTS_DIR/magisk_check.json $orig_json
	
	else
		# If the download fails in the middle it leaves behind a corrupted
		# package. SO let's rename back our backed up old version file to 
		# be use instead.
		echo "Download failed falling back to old version of Magisk"
		mv $APP_DIR/MagiskManager.apk.bak $APP_DIR/MagiskManager.apk
		mv $ZIP_DIR/Magisk.zip.bak $ZIP_DIR/Magisk.zip
	fi	
fi