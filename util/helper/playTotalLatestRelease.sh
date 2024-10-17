#!/bin/bash -x

export TARGET_DIR=~/gameTotalLinuxLatestRelease
export FILE_BASE=totalBuildLinux-Release
export REPO_NAME=GameCore

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh