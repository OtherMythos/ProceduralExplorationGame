#!/usr/bin/env bash

# Usage: ./grid.sh VALUE WIDTH HEIGHT

value="$1"
width="$2"
height="$3"

for ((row=1; row<=height; row++)); do
    line=""
    for ((col=1; col<=width; col++)); do
        line+="$value,"
    done
    echo "$line"
done