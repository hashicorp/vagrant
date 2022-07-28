#!/usr/bin/env bash

echo "🤖 Loading VagrantCI 🤖"

ldir="$(realpath ./.ci-utility-files)"

# Disable IMDS lookup
export AWS_EC2_METADATA_DISABLED=true

# If utility files have not yet been pulled, fetch them
if [ ! -e "${ldir}/.complete" ]; then

    # Validate that we have the AWS CLI available
    if ! command -v aws > /dev/null 2>&1; then
        echo "⚠ ERROR: Missing required aws executable ⚠"
        exit 1
    fi

    # Validate that we have the jq tool available
    if ! command -v jq > /dev/null 2>&1; then
        echo "⚠ ERROR: Missing required jq executable ⚠"
        exit 1
    fi

    # If we have a role defined, assume it so we can get access to files
    if [ "${AWS_ASSUME_ROLE_ARN}" != "" ] && [ "${AWS_SESSION_TOKEN}" = "" ]; then
        if output="$(aws sts assume-role --role-arn "${AWS_ASSUME_ROLE_ARN}" --role-session-name "CI-initializer")"; then
            export CORE_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
            export CORE_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
            id="$(printf '%s' "${output}" | jq -r .Credentials.AccessKeyId)" || failed=1
            key="$(printf '%s' "${output}" | jq -r .Credentials.SecretAccessKey)" || failed=1
            token="$(printf '%s' "${output}" | jq -r .Credentials.SessionToken)" || failed=1
            expire="$(printf '%s' "${output}" | jq -r .Credentials.Expiration)" || failed=1
            if [ "${failed}" = "1" ]; then
                echo "🛑 ERROR: Failed to extract role credentials 🛑"
                exit 1
            fi
            unset output
            export AWS_ACCESS_KEY_ID="${id}"
            export AWS_SECRET_ACCESS_KEY="${key}"
            export AWS_SESSION_TOKEN="${token}"
            export AWS_SESSION_EXPIRATION="${expire}"
        else
            echo "⛔ ERROR: Failed to assume configured AWS role ⛔"
            exit 1
        fi
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

    # Time to load and configure
    if ! popd; then
        echo "⁉ ERROR: Unexpected error, failed to relocate to expected directory ⁉"
        exit 1
    fi
fi

source "${ldir}/common.sh"
export PATH="${PATH}:${ldir}"

# And we are done!
echo "🎉 VagrantCI Loaded! 🎉"
