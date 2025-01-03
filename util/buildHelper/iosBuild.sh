#!/bin/bash -x

START="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#Find development profiles with
#/usr/bin/env xcrun security find-identity -v -p codesigning

#AV_LIBS_DIR=/Users/edward/buildIos/avBuilt/Debug/
#ENGINE_SOURCE_PATH=~/Documents/avEngine
#AV_PROJECT_DIR=/Users/edward/Documents/ProceduralExplorationGame
SOURCE_PATHS=${SCRIPT_DIR}/buildPaths
if [ -f ${SOURCE_PATHS} ]; then
    source ${SOURCE_PATHS}
else
    echo "Define the 'buildPaths' file before running this script."
    exit 1
fi


cmake -DAV_LIBS_DIR=${AV_LIBS_DIR} -DCMAKE_TOOLCHAIN_FILE=${ENGINE_SOURCE_PATH}/CMake/iosbuild.toolchain.cmake -GXcode -DPLATFORM=OS64 -DENGINE_SOURCE_PATH=${ENGINE_SOURCE_PATH} -DAV_PROJECT_DIR=${AV_PROJECT_DIR} -DUSE_STATIC_PLUGINS=True ..