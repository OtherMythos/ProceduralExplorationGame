#!/bin/bash -x

export TARGET_DIR=~/gameLinuxLatestDebug
export FILE_BASE=buildLinux-Debug
export REPO_NAME=ProceduralExplorationGame

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh