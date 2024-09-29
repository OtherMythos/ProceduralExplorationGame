#!/bin/bash -x

export TARGET_DIR=~/gameLinuxLatestRelease
export FILE_BASE=buildLinux-Release

./script/downloadArtifactLatest.sh
./script/executeArtifact.sh