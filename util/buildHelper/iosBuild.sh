#!/bin/bash -x

START="$( pwd )"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
ROOT_DIR="${SCRIPT_DIR}/../../"

SOURCE_PATHS=${SCRIPT_DIR}/buildPaths
if [ -f ${SOURCE_PATHS} ]; then
    source ${SOURCE_PATHS}
else
    echo "Define the 'buildPaths' file before running this script."
    exit 1
fi

BASE_CMAKE_FLAGS="-DAV_LIBS_DIR=${AV_LIBS_DIR} -DCMAKE_TOOLCHAIN_FILE=${ENGINE_SOURCE_PATH}/CMake/iosbuild.toolchain.cmake -GXcode -DPLATFORM=OS64 -DENGINE_SOURCE_PATH=${ENGINE_SOURCE_PATH}"
mkdir -p ${ROOT_DIR}/native/buildIos
cd ${ROOT_DIR}/native/buildIos
cmake ${BASE_CMAKE_FLAGS} ..
cmake --build . --target ALL_BUILD --config Debug

cd ${START}
cmake ${BASE_CMAKE_FLAGS} -DAV_PROJECT_DIR=${AV_PROJECT_DIR} -DUSE_STATIC_PLUGINS=True -DCMAKE_XCODE_ATTRIBUTE_DEVELOPMENT_TEAM=${DEVELOPMENT_TEAM} -DSKIP_EXTRA=True ..