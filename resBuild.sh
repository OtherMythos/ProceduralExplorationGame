#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#docker pull registry.gitlab.com/edherbert/avtools/asset-builder-image:latest
docker build -t asset-builder-image-voxel util/

#Make sure the output exists.
echo "Clearing build directory"
rm -rf ${SCRIPT_DIR}/build
mkdir -p ${SCRIPT_DIR}/build/assets

BUILD_OUTPUT=${SCRIPT_DIR}/build/assets
BUILD_INPUT=${SCRIPT_DIR}/assets/
docker run -it --name asset-builder-container --rm \
    -v "$BUILD_OUTPUT:$BUILD_OUTPUT" \
    -v "$BUILD_INPUT:$BUILD_INPUT" \
    asset-builder-image-voxel -m AssetModuleGox AssetModuleTerrainBMP --input $BUILD_INPUT --output $BUILD_OUTPUT $*

chmod -R 777 $BUILD_OUTPUT
