#/bin/sh

#### zum Start: ./build.sh > build.log-2024-04-16-08-10 2>&1



#export TARGET_PREBUILT_KERNEL="/mnt/aosp-11.r54/kernel/prebuilts/4.19-msm8953-Image.gz"
export ARROW_GAPPS=false
source build/envsetup.sh

date
echo "lunch arrow_sanders-userdebug"
lunch arrow_sanders-userdebug

df -h

## needs to be recorded before starting build, would be too late otherwise
fileTimestampUtcMidnight=$(date -u --date="$(date -u +%Y-%m-%d)" +%s)

## setting limits
#ulimit -a
#getconf ARG_MAX
##ulimit -s 131072
#ulimit -s 262144
#ulimit -a
#getconf ARG_MAX

# To build the OTA ZIP
date
df -h
echo "m otapackage -j$(nproc --all)"
#m otapackage -j$(nproc --all)
m otapackage -j4

#ulimit -a


# To build the system image
date
df -h
echo "m systemimage -j$(nproc --all)"
#m systemimage -j$(nproc --all)

date
df -h

# sign packages
filePathSignedZip="out/target/product/sanders/arrow_sanders-ota-eng.stsc.signed.zip"
filePathUnsignedZip="out/target/product/sanders/arrow_sanders-ota-eng.stsc.zip"

mkdir -p build/make/tools/framework/
cp out/host/linux-x86/framework/signapk.jar build/make/tools/framework/
mkdir -p build/make/tools/lib64
cp out/host/linux-x86/lib64/* build/make/tools/lib64/
mkdir -p out/bin
cp -r out/host/linux-x86/bin/* out/bin/
chmod u+x out/bin/*
ln -s /usr/bin/python2 out/bin/python
export PATH="$(pwd)/out/bin:$PATH"
export LD_LIBRARY_PATH=$(pwd)/out/host/linux-x86/lib64:$LD_LIBRARY_PATH
build/make/tools/releasetools/sign_target_files_apks \
    --default_key_mappings vendor/arrow/security/sanders \
    -o out/target/product/sanders/obj/PACKAGING/target_files_intermediates/arrow_sanders-target_files-eng.stsc.zip \
    out/target/product/sanders/obj/PACKAGING/target_files_intermediates/signed-arrow_sanders-target_files-eng.stsc.zip


# generate OTA
build/tools/releasetools/ota_from_target_files out/target/product/sanders/obj/PACKAGING/target_files_intermediates/signed-arrow_sanders-target_files-eng.stsc.zip ${filePathSignedZip}


# generate file + updater info
targetFileName="Arrow-v11.0-sanders-UNOFFICIAL-OTA-REPLACE_ME-VANILLA.zip"
otaDefinitionFile="arrows-11.0-sanders-ota-definition.json";
otaDefinitionFileSource="${otaDefinitionFile}.source";

fileInfoUnsigned=$(ls -l --time-style="+%s" ${filePathUnsignedZip})
fileSizeUnsigned=$(echo "$fileInfoUnsigned" | tr -s ' ' | cut -d ' ' -f5)
fileDateTimeUtcUnsigned=$(ls -l ${filePathUnsignedZip} --time-style="+%Y-%m-%d_%H:%M:%S" | tr -s ' ' | cut -d ' ' -f6)
fileTimestampUtcUnsigned=$(echo "$fileInfoUnsigned" | tr -s ' ' | cut -d ' ' -f6)
fileInfoSigned=$(ls -l --time-style="+%s" ${filePathSignedZip})
fileSizeSigned=$(echo "$fileInfoSigned" | tr -s ' ' | cut -d ' ' -f5)
fileDateTimeUtcSigned=$(ls -l ${filePathSignedZip} --time-style="+%Y-%m-%d_%H:%M:%S" | tr -s ' ' | cut -d ' ' -f6)
fileTimestampUtcSigned=$(echo "$fileInfoSigned" | tr -s ' ' | cut -d ' ' -f6)

sha256SumValueUnsignedZip=$(sha256sum ${filePathUnsignedZip} | tr -s ' ' | cut -d ' ' -f1)
sha256SumValueSignedZip=$(sha256sum ${filePathSignedZip} | tr -s ' ' | cut -d ' ' -f1)

echo "##############################################################################";
echo "File info:";
echo "Timestamp-UTC: ${fileTimestampUtcMidnight}";
echo "Unsigned-Path: $(pwd)/${filePathUnsignedZip}";
echo "Unsigned-Date/Timestamp-UTC: ${fileDateTimeUtcUnsigned}";
echo "Unsigned-Timestamp-UTC: ${fileTimestampUtcUnsigned}";
echo "Unsigned-FileSize: ${fileSizeUnsigned}";
echo "Unsigned-sha256sum: ${sha256SumValueUnsignedZip}";
echo "------------------------------------------------------------------------------------------------------";
echo "Signed-Path: $(pwd)/${filePathSignedZip}";
echo "Signed-Date/Timestamp-UTC: ${fileDateTimeUtcSigned}";
echo "Signed-Timestamp-UTC: ${fileTimestampUtcSigned}";
echo "Signed-FileSize: ${fileSizeSigned}";
echo "Signed-sha256sum: ${sha256SumValueSignedZip}";
echo "##############################################################################";
echo "created Updater-Json-file $(pwd)/${otaDefinitionFile}";
echo "replace 'PATCH_DATE' by the patch date, e.g. '20220501' in the Updater-Json-file!!!"

cp ${otaDefinitionFileSource} ${otaDefinitionFile}
sed -i 's/TIME_STAMP/'"${fileTimestampUtcMidnight}"'/' ${otaDefinitionFile}
sed -i 's/FILE_SHA256SUM/'"${sha256SumValueUnsignedZip}"'/' ${otaDefinitionFile}
sed -i 's/FILE_SIZE/'"${fileSizeUnsigned}"'/' ${otaDefinitionFile}


date
df -h
