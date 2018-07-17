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

WORKING_DIR=`pwd`

# The tag you want to merge in goes here
BRANCH=android-"$version"_${1}

# Google source url
REPO=https://android.googlesource.com/platform/

# This is the array of upstream repos we track
upstream=()

# This is the array of repos with merge errors
failed=()

# This is the array of repos to blacklist and not merge
blacklist=('manifest' 'prebuilt' 'packages/apps/DeskClock' 'prebuilts/build-tools' 'packages/apps/MusicFX')

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

function get_repos() {
  declare -a repos=( $(repo list | cut -d: -f1) )
  curl --output /tmp/rebase.tmp $REPO --silent # Download the html source of the Android source page
  # Since their projects are listed, we can grep for them
  for i in ${repos[@]}
  do
    if grep -q "$i" /tmp/rebase.tmp; then # If Google has it and
      if grep -q "$i" $WORKING_DIR/manifest/arrow.xml; then # If we have it in our manifest and
        if grep "$i" $WORKING_DIR/manifest/arrow.xml | grep -q "remote=arrow"; then # If we track our own copy of it
          if ! is_in_blacklist $i; then # If it's not in our blacklist
            upstream+=("$i") # Then we need to update it
          else
            echo "$i is in blacklist"
          fi
        fi
      fi
    fi
  done
  rm /tmp/rebase.tmp
}

function delete_upstream() {
  for i in ${upstream[@]}
  do
    rm -rf $i
  done
}

function force_sync() {
  echo "Repo Syncing........."
  sleep 10
  repo sync -c --force-sync >> /dev/null
  if [ $? -eq 0 ]; then
    echo "Repo Sync success"
  else
    echo "Repo Sync failure"
    exit 1
  fi
}

function merge() {
  cd $WORKING_DIR/$1
  git pull $REPO/$1.git -t $BRANCH
  if [ $? -ne 0 ]; then # If merge failed
    failed+=($1) # Add to the list
  fi
}

function print_result() {
  if [ ${#failed[@]} -eq 0 ]; then
    echo ""
    echo "========== "$BRANCH" is merged/pushed sucessfully =========="
    echo "========= Compile and test before pushing  ========="
    echo ""
  else
    echo -e $COLOR_RED
    echo -e "These repos have merge/push errors: \n"
    for i in ${failed[@]}
    do
      echo -e "$i"
    done
    echo -e $COLOR_BLANK
  fi
}

function push() {
  cd $WORKING_DIR/$1
  project_name=`git remote -v | head -n1 | awk '{print $2}' | sed 's/.*\///' | sed 's/\.git//'`
  git remote add gerrit ssh://$username@review.arrowos.net:29418/ArrowOS/$project_name
  git push gerrit HEAD:refs/for/arrow-8.x%topic=tag
  if [ $? -ne 0 ]; then # If merge failed
    failed+=($1) # Add to the list
  fi
}

function gerrit_push() {
  echo "IT IS RECOMMENDED THAT YOU HAVE AN ACCOUNT ON OUR GERRIT AND ADDED YOUR SSH KEYS!!"
  warn_user
  get_repos
  for i in ${upstream[@]}
  do
    echo $i
    push $i
  done
  print_result
}

if [[ ${1} == push ]]; then
  gerrit_push
else

  # Start working
  cd $WORKING_DIR

  # Warn user that this may destroy unsaved work
  # warn_user

  # Get the upstream repos we track
  get_repos

  echo "================================================"
  echo "          Force Syncing all your repos          "
  echo "         and deleting all upstream repos        "
  echo " This is done so we make sure you're up to date "
  echo "================================================"

  delete_upstream
  force_sync

  # Merge every repo in upstream
  for i in ${upstream[@]}
  do
    merge $i
  done

  # Print any repos that failed, so we can fix merge issues
  print_result
fi 
