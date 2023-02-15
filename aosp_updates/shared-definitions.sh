#!/usr/bin/env bash
# Copyright (C) 2016 DirtyUnicorns
# Copyright (C) 2016 Jacob McSwain
# Copyright (C) 2018 ArrowOS
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

WORKING_DIR=$( cd $( dirname $( readlink -f "${BASH_SOURCE[0]}" ) )/../ && pwd )
WORKING_DIR=/mnt/arrowos/st-schilling-scripts-working-dir
WORKING_DIR=/mnt/arrowos/st-schilling-src
# Hardcode your ROM DIR if this fails example: /ssd/arrow/
echo $WORKING_DIR

# The tag you want to merge in goes here
ANDROID_RELEASE_VERSION="63"

# The tag you want to merge in goes here
ANDROID_VERSION_BRANCH="11.0.0_r$ANDROID_RELEASE_VERSION"

# The tag you want to merge in goes here
ANDROID_BRANCH="android-security-$ANDROID_VERSION_BRANCH"

# The tag you want to merge in goes here
ANDROID11_BRANCH="arrow-11.0"

ARROWOS_REPO_SEARCH_PATTERN="refs/heads/arrow-11.0"
ARROWOS_REPO_SEARCH_PATTERN="android_"

# The tag you want to merge in goes here
FEATURE_BRANCH="feature/$ANDROID_VERSION_BRANCH"

REPO_DIR="/mnt/aosp-11"

#ARROWOS_REPO_MANIFEST="/mnt/arrowos/arrow.xml" # contains small amount only
ARROWOS_REPO_MANIFEST="/mnt/arrowos/arrow-Android-11.r$ANDROID_RELEASE_VERSION.xml"

if [ ! -f "$ARROWOS_REPO_MANIFEST" ]; then
    echo "File $ARROWOS_REPO_MANIFEST is missing - copy latest arrow.xml from repo manifest to $ARROWOS_REPO_MANIFEST. Aborting."
    exit 1;
fi


# Google source url
ANDROID_REPO=https://android.googlesource.com/platform

# ArrowOS source user
GIT_REPO_EMAIL="st-schilling@gmx.de"
GIT_REPO_USER="Stefan Schilling"

# ArrowOS source user
ARROWOS_REPO_USER=st-schilling
ARROWOS_REPO_NAME=st-schilling

# ArrowOS source url
ARROWOS_REPO=https://$ARROWOS_REPO_USER@github.com/$ARROWOS_REPO_USER

# ArrowOS source url with username
ARROWOS_REPO_WITH_USER=https://$ARROWOS_REPO_USER@$ARROWOS_REPO
ARROWOS_REPO_WITH_USER=https://$ARROWOS_REPO_USER@github.com/$ARROWOS_REPO_USER

repo_cmd="python3 /mnt/arrowos/ajinasokan/bin/repo"

# This is the array of upstream repos we track
upstream=()

# This is the array of repos with merge errors
failed=()

# This is the array of repos with merge fine
success=()

# This is the array of repos push failed
pushedF=()

# This is the array of repos pushed fine
pushedP=()

# This is the array of repos to blacklist and not merge
blacklist=('cts' 'prebuilt' 'external/chromium-webview' 'prebuilts/build-tools' 'packages/apps/MusicFX' 'packages/apps/FMRadio'
           'packages/apps/Gallery2' 'hardware/qcom/power' 'prebuilts/r8' 'prebuilts/tools' 'tools/metalava'
           'prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9' 'prebuilts/gcc/linux-x86/host/x86_64-linux-glibc2.17-4.8'
           'packages/apps/WallpaperPicker' 'pdk'
           )

# This is the array of repos to which are tagged manually
manuallyTaggedRepos=()

# This is for restricting operation to just the named repos - allowing quicker operation upon testing/error
acceptedRepos=()

# Colors
COLOR_RED='\033[0;31m'
COLOR_BLANK='\033[0m'

function is_in_blacklist() {
  for j in ${blacklist[@]}
  do
    if [ "$j" == "$1" ]; then
      return 0;
    fi
  done
  return 1;
}

function is_manually_tagged() {
  for j in ${manuallyTaggedRepos[@]}
  do
    if [ "$j" == "$1" ]; then
      return 0;
    fi
  done
  return 1;
}

function is_in_accepted_repos() {

  if [[ ${#acceptedRepos[@]} -eq 0 ]]; then
    echo "acceptedRepos unset - accepting all"
    return 0;
  fi

  for j in ${acceptedRepos[@]}
  do
    if [ "$j" == "$1" ]; then
      return 0;
    fi
  done
  return 1;
}

function warn_user() {
  echo "Make sure that you have added your ssh keys on gerrit before proceeding!"
  read -r -p "Do you want to continue? [y/N] " response
  if [[ $response =~ ^([yY][eE][sS]|[yY])$ ]]; then
    if [[ -f /tmp/gu.tmp ]]; then
      username=`cat /tmp/gu.tmp`
      echo "found username: $username"
    else
      echo "Please enter your gerrit username"
      read username
      echo $username > /tmp/gu.tmp
    fi
  else
    echo "PUSH ABORTED!"
    exit 1
  fi
}


function print_branches() {

    text="$1";
  local -n targetPath=$2
  local -n repoName=$3

  echo ""
  echo "======== $text ========"
  echo ""
  length=${#targetPath[@]}
  for (( c=0; c<${length}; c++ ));
  do
    echo -e "${targetPath[$c]} --> ${repoName[$c]}"
  done

}

function get_repos() {
    cd $REPO_DIR || exit 1;
    declare -a complete_repo_info=$($repo_cmd forall -c 'echo "$REPO_PATH : $REPO_PROJECT : $REPO_RREV" | grep ": '$ARROWOS_REPO_SEARCH_PATTERN'"')


    echo "complete_repo_info - w/ search pattern '$ARROWOS_REPO_SEARCH_PATTERN' applied:
    $complete_repo_info";

    declare -a repoPaths=( $(echo "$complete_repo_info" | cut -d: -f1) )
    declare -a repoNames=( $(echo "$complete_repo_info" | cut -d: -f2) )
    curl --output /tmp/rebase.tmp $ANDROID_REPO --silent # Download the html source of the Android source page
    # Since their projects are listed, we can grep for them


    notInManifest=()
    notInManifestRepos=()
    notArrowOsTracked=()
    notArrowOsTrackedRepos=()
    notStSchillingTracked=()
    notStSchillingTrackedRepos=()
    blacklisted=()
    blacklistedRepos=()
    manuallyTaggedRepoNames=()
    manuallyTaggedRepoRepos=()
    notAccepted=()
    notAcceptedRepos=()

    arraylength=${#repoPaths[@]}
    for (( c=0; c<${arraylength}; c++ ));
    do
        i=${repoPaths[$c]}
        arrowsRepoName=${repoNames[$c]}

        $(grep -q "$i" /tmp/rebase.tmp);
        googleHasIt=$?

        ignoreGoogleRepo=1;
        if [[ "$1" == "true" ]]; then
            ignoreGoogleRepo=0
        fi

        if [[ googleHasIt -eq "0" || ignoreGoogleRepo -eq "0" ]]; then # Google has it or ignoreGoogleRepo
            if grep -q "$i" $ARROWOS_REPO_MANIFEST; then # If we have it in our manifest and
                if grep "$i" $ARROWOS_REPO_MANIFEST | grep -q "remote=\"arrow-$ARROWOS_REPO_USER\""; then # If we track our own copy of it
                    if ! is_in_blacklist $i; then # If it's not in our blacklist
                        if ! is_manually_tagged $i; then # If it's not to be tagged manually
                            if is_in_accepted_repos $i; then # If it's specifically cleared by us (or all)
                                upstream+=("$i") # Then we need to update it
                                arrowsRepos+=("$arrowsRepoName") # Then we need to update it
                            else
                                notAccepted+=("$i")
                                notAcceptedRepos+=("$arrowsRepoName")
                            fi # If it's specifically cleared by us (or all)
                        else
                            manuallyTaggedRepoNames+=("$i")
                            manuallyTaggedRepoRepos+=("$arrowsRepoName")
                        fi # If it's not to be tagged manually
                    else
                        blacklisted+=("$i")
                        blacklistedRepos+=("$arrowsRepoName")
                    fi # If it's not in our blacklist
                elif grep "$i" $ARROWOS_REPO_MANIFEST | grep -q 'remote="arrow"'; then # If ArrowOS tracks its copy of it
                    notStSchillingTracked+=("$i")
                    notStSchillingTrackedRepos+=("$arrowsRepoName")
                else
                    notArrowOsTracked+=("$i")
                    notArrowOsTrackedRepos+=("$arrowsRepoName")
                fi # If we or ArrowOS tracks its copy of it
            else
                notInManifest+=("$i")
                notInManifestRepos+=("$arrowsRepoName")
            fi # If we have it in our manifest and
        else
            echo "$i Google hasnt it"
        fi # Google has it or ignoreGoogleRepo
    done
    rm /tmp/rebase.tmp

  print_branches "Branches unknown to $ARROWOS_REPO_MANIFEST" notInManifest notInManifestRepos
  print_branches "Branches unknown to ArrowOS" notArrowOsTracked notArrowOsTrackedRepos
  print_branches "Branches unknown to arrow-$ARROWOS_REPO_USER" notStSchillingTracked notStSchillingTrackedRepos
  print_branches "Branches blacklisted" blacklisted blacklistedRepos
  print_branches "Branches to be tagged manually" manuallyTaggedRepoNames manuallyTaggedRepoRepos
  print_branches "Branches not Accepted" notAccepted notAcceptedRepos
  print_branches "Branches added for operation" upstream arrowsRepos

  echo "##############################################"
  echo "If any repo is missing here and has been added to manifest lately, remember to update file $ARROWOS_REPO_MANIFEST!"
  echo "##############################################"
}

function switchBaseBranch() {
  cd $WORKING_DIR/$1
  checkoutRepoName="$2";

  git status

  echo "checkout BaseBranch: git checkout $checkoutRepoName/$ANDROID11_BRANCH"
  git checkout $checkoutRepoName/$ANDROID11_BRANCH

  git status
}

function resetBaseBranch() {
  cd $WORKING_DIR/$1
  resetPullRepoName="$2";

  git status

  echo "reset BaseBranch: git reset --hard $resetPullRepoName/$ANDROID11_BRANCH"
  git reset --hard $resetPullRepoName/$ANDROID11_BRANCH

  echo "reset pullChanges: git pull $resetPullRepoName $ANDROID11_BRANCH"
  git pull $resetPullRepoName $ANDROID11_BRANCH

  git status
}

function print_result_branch() {


    text="$1";
  local -n repo=$2

  echo ""
  echo "======== $text ========"
  echo ""
  for i in ${repo[@]}
  do
    echo -e "$i"
  done
}

function print_result() {
  if [ ${#failed[@]} -eq 0 ]; then
    echo ""
    echo "========== "$FEATURE_BRANCH" is $1 sucessfully =========="
    echo ""
  else
    echo -e $COLOR_RED
    echo -e "========== These repos have $1 errors: ==========\n"
    for i in ${failed[@]}
    do
      echo -e "$i"
    done
    echo -e $COLOR_BLANK
  fi

  print_result_branch "$FEATURE_BRANCH has been $1 successfully" success

  print_result_branch "tag $ANDROID_BRANCH has been $2 successfully to these repos" pushedP

  print_result_branch "tag $ANDROID_BRANCH $2 has failed to these repos" pushedF
}


git config --global core.askpass /usr/bin/ksshaskpass
git config --global user.name "$GIT_REPO_USER"
git config --global user.email "$GIT_REPO_EMAIL"
export GIT_ASKPASS=`which ksshaskpass`
