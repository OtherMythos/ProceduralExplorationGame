#!/bin/bash -x

export TARGET_DIR=~/gameLinuxLatestDebug
export FILE_BASE=buildLinux-Debug

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh