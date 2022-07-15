#!/bin/bash

ubxtool="$(which ubxtool) -P 27"

find /dev -name 'ttyACM*' | xargs -n1 ./get_id.sh



