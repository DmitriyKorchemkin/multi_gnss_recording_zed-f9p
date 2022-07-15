#!/bin/bash

ubxtool="$(which ubxtool) -P 27"

path=$1
echo $(${ubxtool} -p SEC-UNIQID localhost:2947:${path} | grep 'uniqueId' | tail -n1 | awk '{print $7; }')
