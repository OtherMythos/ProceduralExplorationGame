#!/bin/bash -x

export TARGET_DIR=~/gameLinuxLatestRelease
export FILE_BASE=buildLinux-Release
export REPO_NAME=ProceduralExplorationGame

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh