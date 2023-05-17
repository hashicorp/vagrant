#!/bin/sh -
if [ -e bootstrap-salt.sh ]; then
  sh bootstrap-salt.sh "$@"
else
  exit 1
fi
