#!/bin/bash -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#Define a file at 'resBuildFlags.sh' to add some extra flags.
FLAGS_FILE=${SCRIPT_DIR}/resBuildFlags.sh
if [ -f ${FLAGS_FILE} ]; then
    source ${FLAGS_FILE}
fi

docker pull ghcr.io/othermythos/asset-builder-image-voxel:latest
#docker build -t asset-builder-image-voxel util/

#Make sure the output exists.
if [ -v "$SKIP_DELETION" ]; then
    echo "Clearing build directory"
    rm -rf ${SCRIPT_DIR}/build
    mkdir -p ${SCRIPT_DIR}/build/assets
fi

BUILD_OUTPUT=${SCRIPT_DIR}/build/assets
BUILD_INPUT=${SCRIPT_DIR}/assets/
docker run --name asset-builder-container --rm \
    -v "$BUILD_OUTPUT:$BUILD_OUTPUT" \
    -v "$BUILD_INPUT:$BUILD_INPUT" ${VOLUME_EXTRAS} \
    ghcr.io/othermythos/asset-builder-image-voxel:latest -m AssetModuleGox --input $BUILD_INPUT --output $BUILD_OUTPUT $*

#chmod -R 777 $BUILD_OUTPUT
