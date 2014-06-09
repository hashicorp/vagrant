#!/bin/sh -

# We just download the bootstrap script by default and execute that.
if [ -x /usr/bin/fetch ]; then
    /usr/bin/fetch -o - https://bootstrap.saltstack.com | sh -s -- "$@"
elif [ -x /usr/bin/curl ]; then
    /usr/bin/curl -L https://bootstrap.saltstack.com | sh -s -- "$@"
else
    python \
        -c 'import urllib; print urllib.urlopen("https://bootstrap.saltstack.com").read()' \
        | sh -s -- "$@"
fi
