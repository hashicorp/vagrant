#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
if ! root="$( cd -P "$( dirname "$csource" )/../" && pwd )"; then
    echo "⛔ ERROR: Failed to determine root local directory ⛔" >&2
    exit 1
fi

export root
export ci_bin_dir="${root}/.ci/.ci-utility-files"

# shellcheck source=/dev/null
if ! source "${ci_bin_dir}/common.sh"; then
    echo "⛔ ERROR: Failed to source Vagrant CI common file ⛔" >&2
    exit 1
fi
export PATH="${PATH}:${ci_bin_dir}"

# And we are done!
debug "VagrantCI Loaded"
