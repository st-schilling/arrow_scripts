def basejobname = DEVICE
def BUILD_TREE = "/var/lib/jenkins/workspace/builder"

node {
	currentBuild.displayName = basejobname

	stage('Sync') {
		sh '''#!/bin/bash
		cd '''+BUILD_TREE+'''
		rm -rf .repo/local_manifests
		echo "Resetting current working tree...."
	        repo forall -c "git reset --hard" > /dev/null
		echo "Reset complete!"
	        repo forall -c "git clean -f -d"
	        repo sync -d -c --force-sync --no-tags --no-clone-bundle
		'''
	}
	stage('Clean') {
		sh '''#!/bin/bash
		cd '''+BUILD_TREE+'''
		make clean
		make clobber
		'''
	}
	stage('Build') {
		sh '''#!/bin/bash +e
		cd '''+BUILD_TREE+'''
		. build/envsetup.sh
		export USE_CCACHE=1
		export CCACHE_COMPRESS=1
		lunch arrow_$DEVICE-$BUILD_TYPE
		mka bacon
		'''
	}
	stage('Upload') {
		sh '''#!/bin/bash
		set -e
		cd '''+BUILD_TREE+'''
		# Misc upload funcs
		'''
	}
}
