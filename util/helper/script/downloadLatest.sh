#!/bin/bash -x

#TARGET_DIR=~/gameWindows
TARGET_URL=""
#FILE_BASE=buildWindows

if ! command -v wget &> /dev/null
then
    echo "wget could not be found"
    exit 1
fi

if ! command -v unzip &> /dev/null
then
    echo "unzip could not be found"
    exit 1
fi

rm -rf $TARGET_DIR
if [ ! -d "$TARGET_DIR" ]; then
    echo "Directory $TARGET_DIR doesn't exist"
    mkdir -p $TARGET_DIR
fi

echo "Attempting to download latest game to "
TARGET_URL=$(curl -s "https://api.github.com/repos/OtherMythos/${REPO_NAME}/releases" | grep "$FILE_BASE" | grep -m 1 browser_download_url | grep -Eo 'https://[^ >]+.zip'|head -1)
wget "$TARGET_URL"
#FILE_NAME=${echo "$TARGET_URL" | grep -E "$FILE_BASE[^ >]+.zip"}
#echo $FILE_NAME
for file in *.zip; do
    unzip $file -d $TARGET_DIR
    rm $file
    break
done