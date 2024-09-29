#!/bin/bash -x

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

source token

if [ -z "${TARGET_DIR}" ]; then
    echo "Only run this file with environment variables set"
    exit 1
fi

mkdir ${TARGET_DIR}

declare -a arr=(${FILE_BASE})
for build in "${arr[@]}"
do
    ARTIFACT_ID=$(curl -s 'https://api.github.com/repos/OtherMythos/ProceduralExplorationGame/actions/artifacts' |
        python3 ${SCRIPT_DIR}/parseArtifactsJSON.py $build)

    curl -L \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: token ${AUTHORIZATION_TOKEN}" \
        "https://api.github.com/repos/OtherMythos/ProceduralExplorationGame/actions/artifacts/${ARTIFACT_ID}/zip" > ${TARGET_DIR}/game.zip

done

cd ${TARGET_DIR}
unzip ${TARGET_DIR}/*
chmod +x $TARGET_DIR/*
ls $TARGET_DIR/*