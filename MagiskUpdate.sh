#!/bin/sh

#LazyAss MagiskUpdate
CUR_DIR=`pwd`
APP_DIR="$CUR_DIR/vendor/dot/prebuilt/app/magisk"
ZIP_DIR="$CUR_DIR/vendor/dot/prebuilt/zips"
SCRIPTS_DIR="$CUR_DIR/dot_scripts"
orig_json='https://raw.githubusercontent.com/topjohnwu/MagiskManager/update/magisk_update.json'

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
	wget -q --show-progress -O $APP_DIR/MagiskManager.apk $app_link
	echo " "
	echo "Downloading Latest Magisk zip"
	wget -q --show-progress -O $ZIP_DIR/Magisk.zip $zip_link

	# Replacing our magisk_check.json with the original json 
        # from github to cross check it later for updates and 
        # also to avoid re-downloading of the same versions again.
	wget -q -O $SCRIPTS_DIR/magisk_check.json $orig_json
fi