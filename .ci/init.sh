#!/usr/bin/env bash

. "${root}/.ci/load-ci.sh"

export DEBIAN_FRONTEND="noninteractive"
export PATH="${PATH}:${root}/.ci"
