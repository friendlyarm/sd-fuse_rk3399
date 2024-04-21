#!/bin/bash

if [ $# -ne 1 ] && [ $# -ne 2 ]; then
    echo "Usage: $0 <FILE> [DIR]"
    exit 1
fi
if [ $# -eq 1 ]; then
    sudo su -c "tar xvzfp \"$1\" --numeric-owner --same-owner"
elif [ $# -eq 2 ]; then
    sudo su -c "tar xvzfp \"$1\" -C \"$2\" --numeric-owner --same-owner"
fi