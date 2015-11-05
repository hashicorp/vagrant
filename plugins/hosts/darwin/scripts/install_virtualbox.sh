#!/bin/bash
set -e

hdiutil attach $1
cd /Volumes/VirtualBox/
sudo installer -pkg VirtualBox.pkg -target "/"
cd /tmp
flag=1
while [ $flag -ne 0 ]; do
    sleep 1
    set +e
    hdiutil detach /Volumes/VirtualBox/
    flag=$?
    set -e
done
