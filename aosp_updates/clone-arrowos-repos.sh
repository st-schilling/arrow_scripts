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


# load generic shared definitions
. ./shared-definitions.sh

# This is for manually tagging only - leave empty at any time
manuallyTaggedRepos=()

# This is for restricting operation to just the named repos - allowing quicker operation upon testing/error
acceptedRepos=()


function clone() {
  mkdir -p $WORKING_DIR/$1
  cd $WORKING_DIR/$1
  
  echo "git clone -b $LOCAL_BRANCH --single-branch $ARROWOS_REPO/$2.git $WORKING_DIR/$1"
  git clone -b $LOCAL_BRANCH --single-branch $ARROWOS_REPO/$2.git $WORKING_DIR/$1
  
  if [ $? -ne 0 ]; then # If merge failed
    failed+=($1) # Add to the list
  else
    success+=($1)
  fi
}


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


# Merge every repo in upstream
#for i in ${upstream[@]}
arraylength=${#upstream[@]}
for (( i=0; i<${arraylength}; i++ ));
do
  clone ${upstream[$i]} ${arrowsRepos[$i]}
done
