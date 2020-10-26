#!/usr/bin/env bash

echo "🤖 Loading VagrantCI 🤖"

ldir="$(realpath ./.ci-utility-files)"

# If utility files have not yet been pulled, fetch them
if [ ! -e "${ldir}/.complete" ]; then

    # Validate that we have the AWS CLI available
    if ! command -v aws > /dev/null 2>&1; then
        echo "⚠ ERROR: Missing required aws executable ⚠"
        exit 1
    fi

    # Create a local directory to stash our stuff in
    if ! mkdir -p "${ldir}"; then
        echo "⛔ ERROR: Failed to create utility file directory ⛔"
        exit 1
    fi

    # Jump into local directory and grab files
    if ! pushd "${ldir}"; then
        echo "⁉ ERROR: Unexpected error, failed to relocate to expected directory ⁉"
        exit 1
    fi

    if ! aws s3 sync "${VAGRANT_CI_LOADER_BUCKET}/ci-files/" ./; then
        echo "🛑 ERROR: Failed to retrieve utility files 🛑"
        exit 1
    fi

    if ! chmod a+x ./*; then
        echo "⛔ ERROR: Failed to set permissions on CI files ⛔"
        exit 1
    fi

    # Mark that we have pulled files
    touch .complete || echo "WARNING: Failed to mark CI files as fetched"
fi

# Time to load and configure
if ! popd; then
    echo "⁉ ERROR: Unexpected error, failed to relocate to expected directory ⁉"
    exit 1
fi

source "${ldir}/common.sh"
export PATH="${PATH}:${ldir}"

# And we are done!
echo "🎉 VagrantCI Loaded! 🎉"
