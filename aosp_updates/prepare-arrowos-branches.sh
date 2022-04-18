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

# although no updates are retrieved from Google AOSP, all repositories are needed for later operation
prepareUnknownToGoogle=true;

# This is for manually tagging only - leave empty at any time
manuallyTaggedRepos=()

# This is for restricting operation to just the named repos - allowing quicker operation upon testing/error
acceptedRepos=()

function deleteFeatureBranch() {
  cd $WORKING_DIR/$1
  
  git status
  
  echo "checkout FeatureBranch: git branch -D $FEATURE_BRANCH"
  git branch -D $FEATURE_BRANCH
  
  git status
}

function switchFeatureBranch() {
  cd $WORKING_DIR/$1
  
  git status
  
  echo "checkout FeatureBranch: git checkout -b $FEATURE_BRANCH $ANDROID11_BRANCH"
  git checkout -b $FEATURE_BRANCH $ANDROID11_BRANCH
  
  git status
}


# Start working
cd $WORKING_DIR

# Warn user that this may destroy unsaved work
# warn_user

# Get the upstream repos we track
get_repos $prepareUnknownToGoogle

echo "================================================"
echo "          Force Syncing all your repos          "
echo "         and deleting all upstream repos        "
echo " This is done so we make sure you're up to date "
echo "================================================"


# Merge every repo in upstream
arraylength=${#upstream[@]}
for (( i=0; i<${arraylength}; i++ ));
do
  echo "cd $WORKING_DIR/${upstream[$i]}"
  switchBaseBranch ${upstream[$i]}
  resetBaseBranch ${upstream[$i]}
  deleteFeatureBranch ${upstream[$i]}
  switchFeatureBranch ${upstream[$i]}
done
