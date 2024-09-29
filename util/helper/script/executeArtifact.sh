#!/bin/bash -x

cd $TARGET_DIR
for file in "$TARGET_DIR/*"; do
    $file
    break
done