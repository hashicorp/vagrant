#!/usr/bin/env bash

# shellcheck disable=SC1091
echo "🤖 Loading VagrantCI 🤖"

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
if ! root="$( cd -P "$( dirname "$csource" )/../" && pwd )"; then
    echo "⛔ ERROR: Failed to determine root local directory ⛔"
    exit 1
fi

export root
export ci_bin_dir="${root}/.ci/.ci-utility-files"

if ! source "${ci_bin_dir}/common.sh"; then
    echo "⛔ ERROR: Failed to source Vagrant CI common file ⛔"
    exit 1
fi
export PATH="${PATH}:${ci_bin_dir}"

# And we are done!
echo "🎉 VagrantCI Loaded! 🎉"
