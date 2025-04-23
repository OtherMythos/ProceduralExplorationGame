#!/bin/bash -x

export TARGET_DIR=~/gameTotalLinuxLatestDebug
export FILE_BASE=totalBuildLinux-Debug
export REPO_NAME=GameCore

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh $*