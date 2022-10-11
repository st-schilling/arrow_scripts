#!/bin/sh

python3 /mnt/arrowos/ajinasokan/bin/repo init --depth=1 -u https://st-schilling@github.com/st-schilling/android_manifest.git -b refs/tags/11.0.0_r60
python3 /mnt/arrowos/ajinasokan/bin/repo init --depth=1 -u https://st-schilling@github.com/st-schilling/android_manifest.git -b feature/11.0.0_r58-update-build
python3 /mnt/arrowos/ajinasokan/bin/repo sync  -f --force-sync --no-clone-bundle --no-tags -j4
git clone -b arrow-11.0 --single-branch https://github.com/ArrowOS-Devices/android_kernel_motorola_sanders.git kernel/motorola/msm8953
git clone -b arrow-11.0 --single-branch https://github.com/ArrowOS-Devices/android_device_motorola_sanders.git device/motorola/sanders
git clone -b arrow-11.0 --single-branch https://github.com/ArrowOS-Devices/android_vendor_motorola_sanders.git vendor/motorola/sanders
cp ../arrowos/arrows-11.0-sanders-ota-definition.json.source .
mkdir -p vendor/arrow/security/sanders
cp ~/.android-certs/unprotected/* vendor/arrow/security/sanders/
cp ../arrowos/build.sh .
