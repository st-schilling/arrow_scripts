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
tagPushUnknownToGoogle=true;

# This is the array of repos to which are tagged manually
manuallyTaggedRepos=()

# This is for restricting operation to just the named repos - allowing quicker operation upon testing/error
## Note: 'packages/apps/Updater' is disabled by shared-definitions.sh/blacklist!
acceptedRepos=()

function tagBranch() {
  echo "cd $WORKING_DIR/$1"
  cd $WORKING_DIR/$1
  
  commitMessage="Merge tag '$ANDROID_BRANCH' of $ARROWOS_REPO/$2 into HEAD

Android 11.0.0 Release $ANDROID_RELEASE_VERSION"
  
  echo "tag branch: git tag -a $ANDROID_VERSION_BRANCH -m \"$commitMessage\"";

  git tag -a $ANDROID_VERSION_BRANCH -m "$commitMessage"
  if [ $? -ne 0 ]; then # If merge failed
    failed+=($1) # Add to the list
  else
    success+=($1)
  fi
}

function push() {
  cd $WORKING_DIR/$1

  echo "pushing $4: $3";
  echo "git push $ARROWOS_REPO_WITH_USER/$2.git $3";

  git push $ARROWOS_REPO_WITH_USER/$2.git $3
  if [ $? -ne 0 ]; then # If merge failed
    pushedF+=($1) # Add to the list
  else
    pushedP+=($1)
  fi
}

# Start working
cd $WORKING_DIR

# Warn user that this may destroy unsaved work
# warn_user

# Get the upstream repos we track
get_repos $tagPushUnknownToGoogle

echo "================================================"
echo "          Force Syncing all your repos          "
echo "         and deleting all upstream repos        "
echo " This is done so we make sure you're up to date "
echo "================================================"



# Merge every repo in upstream
arraylength=${#upstream[@]}
for (( i=0; i<${arraylength}; i++ ));
do
  echo "#########################################"

  switchBaseBranch ${upstream[$i]}
  resetBaseBranch ${upstream[$i]}
  tagBranch ${upstream[$i]} ${arrowsRepos[$i]}
  
  echo "#########################################"
done

if [ ${#failed[@]} -eq 0 ]; then
    arraylength=${#upstream[@]}
    for (( i=0; i<${arraylength}; i++ ));
    do
        push ${upstream[$i]} ${arrowsRepos[$i]} $FEATURE_BRANCH "branch"
        push ${upstream[$i]} ${arrowsRepos[$i]} $ANDROID_VERSION_BRANCH "tag"
    done
fi

# Print any repos that failed, so we can fix merge issues
print_result "tagged" "pushed"
