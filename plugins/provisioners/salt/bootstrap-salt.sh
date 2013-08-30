#!/bin/sh -

# We just download the bootstrap script by default and execute that.
python \
    -c 'import urllib; print urllib.urlopen("http://bootstrap.saltstack.org").read()' \
    | sh -s -- "$@"
