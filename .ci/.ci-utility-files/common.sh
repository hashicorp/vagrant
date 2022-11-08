#!/usr/bin/env bash

# shellcheck disable=SC2119
# shellcheck disable=SC2164

# Common variables
export full_sha="${GITHUB_SHA}"
export short_sha="${full_sha:0:8}"
export ident_ref="${GITHUB_REF#*/*/}"
export repository="${GITHUB_REPOSITORY}"
export repo_owner="${repository%/*}"
export repo_name="${repository#*/}"
# shellcheck disable=SC2153
export asset_cache="${ASSETS_PRIVATE_SHORTTERM}/${repository}/${GITHUB_ACTION}"
export run_number="${GITHUB_RUN_NUMBER}"
export run_id="${GITHUB_RUN_ID}"
export job_id="${run_id}-${run_number}"
readonly hc_releases_metadata_filename="release-meta.json"

if [ -z "${ci_bin_dir}" ]; then
    if ci_bin_dir="$(realpath ./.ci-bin)"; then
        export ci_bin_dir
    else
        echo "ERROR: Failed to create the local CI bin directory"
        exit 1
    fi
fi


# We are always noninteractive
export DEBIAN_FRONTEND=noninteractive

# Wraps the aws CLI command to support
# role based access. It will check for
# expected environment variables when
# a role has been assumed. If they are
# not found, it will assume the configured
# role. If the role has already been
# assumed, it will check that the credentials
# have not timed out, and re-assume the
# role if so. If no role information is
# provided, it will just pass the command
# through directly
#
# NOTE: Required environment variable: AWS_ASSUME_ROLE_ARN
function aws() {
    # Grab the actual aws cli path
    if ! aws_path="$(which aws)"; then
        (>&2 echo "AWS error: failed to locate aws cli executable")
        return 1
    fi
    # First, check if the role ARN environment variable is
    # configured. If it is not, just pass through.
    if [ "${AWS_ASSUME_ROLE_ARN}" = "" ]; then
        "${aws_path}" "${@}"
        return $?
    fi
    # Check if a role has already been assumed. If it
    # has, validate the credentials have not timed out
    # and pass through.
    if [ "${AWS_SESSION_TOKEN}" != "" ]; then
        # Cut off part of the expiration so we don't end up hitting
        # the expiration just as we make our call
        expires_at=$(date -d "${AWS_SESSION_EXPIRATION} - 20 sec" "+%s")
        if (( "${expires_at}" > $(date +%s) )); then
            "${aws_path}" "${@}"
            return $?
        fi
        # If we are here then the credentials were not
        # valid so clear the session token and restore
        # original credentials
        unset AWS_SESSION_TOKEN
        unset AWS_SESSION_EXPIRATION
        export AWS_ACCESS_KEY_ID="${CORE_AWS_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${CORE_AWS_SECRET_ACCESS_KEY}"
    fi
    # Now lets assume the role
    if aws_output="$("${aws_path}" sts assume-role --role-arn "${AWS_ASSUME_ROLE_ARN}" --role-session-name "VagrantCI@${repo_name}-${job_id}")"; then
        export CORE_AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}"
        export CORE_AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}"
        id="$(printf '%s' "${aws_output}" | jq -r .Credentials.AccessKeyId)" || failed=1
        key="$(printf '%s' "${aws_output}" | jq -r .Credentials.SecretAccessKey)" || failed=1
        token="$(printf '%s' "${aws_output}" | jq -r .Credentials.SessionToken)" || failed=1
        expire="$(printf '%s' "${aws_output}" | jq -r .Credentials.Expiration)" || failed=1
        if [ "${failed}" = "1" ]; then
            (>&2 echo "Failed to extract assume role credentials")
            return 1
        fi
        unset aws_output
        export AWS_ACCESS_KEY_ID="${id}"
        export AWS_SECRET_ACCESS_KEY="${key}"
        export AWS_SESSION_TOKEN="${token}"
        export AWS_SESSION_EXPIRATION="${expire}"
    else
        (>&2 echo "AWS assume role error: ${output}")
        return 1
    fi
    # And we can execute!
    "${aws_path}" "${@}"
}

# Path to file used for output redirect
# and extracting messages for warning and
# failure information sent to slack
function output_file() {
    if [ "${1}" = "clean" ] && [ -f "${ci_output_file_path}" ]; then
        rm -f "${ci_output_file_path}"
    fi
    if [ -z "${ci_output_file_path}" ] || [ ! -f "${ci_output_file_path}" ]; then
        ci_output_file_path="$(mktemp)"
    fi
    printf "%s" "${ci_output_file_path}"
}

# Write failure message, send error to configured
# slack, and exit with non-zero status. If an
# "$(output_file)" file exists, the last 5 lines will be
# included in the slack message.
#
# $1: Failure message
function fail() {
    (>&2 echo "ERROR: ${1}")
    if [ -f "$(output_file)" ]; then
        slack -s error -m "ERROR: ${1}" -f "$(output_file)" -T 5
    else
        slack -s error -m "ERROR: ${1}"
    fi
    exit 1
}

# Write warning message, send warning to configured
# slack
#
# $1: Warning message
function warn() {
    (>&2 echo "WARN:  ${1}")
    if [ -f "$(output_file)" ]; then
        slack -s warn -m "WARNING: ${1}" -f "$(output_file)"
    else
        slack -s warn -m "WARNING: ${1}"
    fi
}

# Execute command while redirecting all output to
# a file (file is used within fail mesage on when
# command is unsuccessful). Final argument is the
# error message used when the command fails.
#
# $@{1:$#-1}: Command to execute
# $@{$#}: Failure message
function wrap() {
    i=$(("${#}" - 1))
    if ! wrap_raw "${@:1:$i}"; then
        cat "$(output_file)"
        fail "${@:$#}"
    fi
    rm "$(output_file)"
}

# Execute command while redirecting all output to
# a file. Exit status is returned.
function wrap_raw() {
    output_file "clean" > /dev/null 2>&1
    "${@}" > "$(output_file)" 2>&1
    return $?
}

# Execute command while redirecting all output to
# a file (file is used within fail mesage on when
# command is unsuccessful). Command output will be
# streamed during execution. Final argument is the
# error message used when the command fails.
#
# $@{1:$#-1}: Command to execute
# $@{$#}: Failure message
function wrap_stream() {
    i=$(("${#}" - 1))
    if ! wrap_stream_raw "${@:1:$i}"; then
        fail "${@:$#}"
    fi
    rm "$(output_file)"
}

# Execute command while redirecting all output
# to a file. Command output will be streamed
# during execution. Exit status is returned
function wrap_stream_raw() {
    output_file "clean"
    "${@}" > "$(output_file)" 2>&1 &
    pid=$!
    until [ -f "$(output_file)" ]; do
        sleep 0.1
    done
    tail -f --quiet --pid "${pid}" "$(output_file)"
    wait "${pid}"
    return $?
}


# Send command to packet device and wrap
# execution
# $@{1:$#-1}: Command to execute
# $@{$#}: Failure message
function pkt_wrap() {
    wrap packet-exec run -quiet -- "${@}"
}

# Send command to packet device and wrap
# execution
# $@: Command to execute
function pkt_wrap_raw() {
    wrap_raw packet-exec run -quiet -- "${@}"
}

# Send command to packet device and wrap
# execution with output streaming
# $@{1:$#-1}: Command to execute
# $@{$#}: Failure message
function pkt_wrap_stream() {
    wrap_stream packet-exec run -quiet -- "${@}"
}

# Send command to packet device and wrap
# execution with output streaming
# $@: Command to execute
function pkt_wrap_stream_raw() {
    wrap_stream_raw packet-exec run -quiet -- "${@}"
}

# Wrap the pushd command so we fail
# if the pushd command fails. Arguments
# are just passed through.
function pushd() {
    wrap command pushd "${@}" "Failed to push into directory"
}

# Wrap the popd command so we fail
# if the popd command fails. Arguments
# are just passed through.
# shellcheck disable=SC2120
function popd() {
    wrap command popd "${@}" "Failed to pop from directory"
}

# Generates location within the asset storage
# bucket to retain built assets.
function asset_location() {
    local dst=""
    if [ -z "${tag}" ]; then
        dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${ident_ref}"
    else
        if [[ "${tag}" = *"+"* ]]; then
            dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${tag}"
        else
            dst="${ASSETS_PRIVATE_BUCKET}/${repository}/${tag}"
        fi
    fi
    echo -n "${dst}"
}

# Upload assets to the asset storage bucket.
#
# $1: Path to asset file or directory to upload
function upload_assets() {
    if [ "${1}" = "" ]; then
        fail "Parameter required for asset upload"
    fi
    if [ -d "${1}" ]; then
        wrap aws s3 cp --recursive "${1}" "$(asset_location)/" \
             "Upload to asset storage failed"
    else
        wrap aws s3 cp "${1}" "$(asset_location)/" \
             "Upload to asset storage failed"
    fi
}

# Download assets from the asset storage bucket. If
# destination is not provided, remote path will be
# used locally.
#
# $1: Path to asset or directory to download
# $2: Optional destination for downloaded assets
function download_assets() {
    local dst
    local src
    local remote

    if [ "${1}" = "" ]; then
        fail "At least one parameter required for asset download"
    fi
    if [ "${2}" = "" ]; then
        dst="${1#/}"
    else
        dst="${2}"
    fi
    mkdir -p "${dst}"
    src="$(asset_location)/${1#/}"
    remote=$(aws s3 ls "${src}")
    if [[ "${remote}" = *" PRE "* ]]; then
        mkdir -p "${dst}"
        wrap aws s3 cp --recursive "${src%/}/" "${dst}" \
             "Download from asset storage failed"
    else
        mkdir -p "$(dirname "${dst}")"
        wrap aws s3 cp "${src}" "${dst}" \
             "Download from asset storage failed"
    fi
}

# Upload assets to the cache storage bucket.
#
# $1: Path to asset file or directory to upload
function upload_cache() {
    if [ "${1}" = "" ]; then
        fail "Parameter required for cache upload"
    fi
    if [ -d "${1}" ]; then
        wrap aws s3 cp --recursive "${1}" "${asset_cache}/" \
             "Upload to cache failed"
    else
        wrap aws s3 cp "${1}" "${asset_cache}/" \
             "Upload to cache failed"
    fi
}

# Download assets from the cache storage bucket. If
# destination is not provided, remote path will be
# used locally.
#
# $1: Path to asset or directory to download
# $2: Optional destination for downloaded assets
function download_cache() {
    local dst
    local src
    local remote

    if [ "${1}" = "" ]; then
        fail "At least one parameter required for cache download"
    fi
    if [ "${2}" = "" ]; then
        dst="${1#/}"
    else
        dst="${2}"
    fi
    mkdir -p "${dst}"
    src="${asset_cache}/${1#/}"
    remote=$(aws s3 ls "${src}")
    if [[ "${remote}" = *" PRE "* ]]; then
        mkdir -p "${dst}"
        wrap aws s3 cp --recursive "${src%/}/" "${dst}" \
             "Download from cache storage failed"
    else
        mkdir -p "$(dirname "${dst}")"
        wrap aws s3 cp "${src}" "${dst}" \
             "Download from cache storage failed"
    fi
}

# Sign a file. This uses signore to generate a
# gpg signature for a given file. If the destination
# path for the signature is not provided, it will
# be stored at the origin path with a .sig suffix
#
# $1: Path to origin file
# $2: Path to store signature (optional)
function sign_file() {
    # Check that we have something to sign
    if [ "${1}" = "" ]; then
        fail "Origin file is required for signing"
    fi

    # Validate environment has required signore variables set
    if [ "${SIGNORE_CLIENT_ID}" = "" ]; then
        fail "Cannot sign file, SIGNORE_CLIENT_ID is not set"
    fi
    if [ "${SIGNORE_CLIENT_SECRET}" = "" ]; then
        fail "Cannot sign file, SIGNORE_CLIENT_SECRET is not set"
    fi
    if [ "${SIGNORE_SIGNER}" = "" ]; then
        fail "Cannot sign file, SIGNORE_SIGNER is not set"
    fi

    local origin="${1}"
    local destination="${2}"
    if [ "${destination}" = "" ]; then
        destination="${origin}.sig"
    fi

    if ! command -v signore; then
        install_hashicorp_tool "signore"
    fi

    if [ -e "${destination}" ]; then
        fail "File already exists at signature destination path (${destination})"
    fi

    wrap_stream signore sign --dearmor --file "${origin}" --out "${destination}" \
        "Failed to sign file"
}

# Validate arguments for GitHub release. Checks for
# two arguments and that second argument is an exiting
# file asset, or directory.
#
# $1: GitHub tag name
# $2: Asset file or directory of assets
function release_validate() {
    if [ "${1}" = "" ]; then
        fail "Missing required position 1 argument (TAG) for release"
    fi
    if [ "${2}" = "" ]; then
        fail "Missing required position 2 argument (PATH) for release"
    fi
    if [ ! -e "${2}" ]; then
        fail "Path provided for release (${2}) does not exist"
    fi
}

# Generate a GitHub release
#
# $1: GitHub tag name
# $2: Asset file or directory of assets
function release() {
    release_validate "${@}"
    local tag_name="${1}"
    local assets="${2}"
    local body

    if ! command -v ghr; then
        install_ghr
    fi

    body="$(release_details "${tag_name}")"
    if [ -z "${body}" ]; then
        body="New ${repo_name} release - ${tag_name}"
    fi
    if ! wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${tag_name}" \
             -b "${body}" -delete "${tag_name}" "${assets}"; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${tag_name}" \
             -b "${body}" "${tag_name}" "${assets}" "Failed to create release for version ${tag_name}"
    fi
}

# Generate a GitHub prerelease
#
# $1: GitHub tag name
# $2: Asset file or directory of assets
function prerelease() {
    release_validate "${@}"
    local ptag
    if [[ "${1}" != *"+"* ]]; then
        ptag="${1}+${short_sha}"
    else
        ptag="${1}"
    fi
    local assets="${2}"

    if ! command -v ghr; then
        install_ghr
    fi

    if ! wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -delete -prerelease "${ptag}" "${assets}"; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -prerelease "${ptag}" "${assets}" \
             "Failed to create prerelease for version ${1}"
    fi
    echo -n "${ptag}"
}

# Generate a GitHub draft release
#
# $1: GitHub release name
# $2: Asset file or directory of assets
function draft_release() {
    local ptag="${1}"
    local assets="${2}"

    if ! command -v ghr; then
        install_ghr
    fi

    if ! wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -replace -delete -draft "${ptag}" "${assets}"; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -replace -draft "${ptag}" "${assets}" \
             "Failed to create draft for version ${1}"
    fi
    echo -n "${ptag}"
}


# Generate details of the release. This will consist
# of a link to the changelog if we can properly detect
# it based on current location.
#
# $1: Tag name
#
# Returns: details content
function release_details() {
    local tag_name="${1}"
    local proj_root
    if ! proj_root="$(git rev-parse --show-toplevel)"; then
        return
    fi
    if [ -z "$(git tag -l "${tag_name}")" ] || [ ! -f "${proj_root}/CHANGELOG.md" ]; then
        return
    fi
    echo -en "CHANGELOG:\n\nhttps://github.com/${repository}/blob/${tag_name}/CHANGELOG.md"
}

# Check if version string is valid for release
#
# $1: Version
# Returns: 0 if valid, 1 if invalid
function valid_release_version() {
    if [[ "${1}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}

# Validate arguments for HashiCorp release. Ensures asset
# directory exists, and checks that the SHASUMS and SHASUM.sig
# files are present.
#
# $1: Asset directory
function hashicorp_release_validate() {
    local directory="${1}"
    local sums
    local sigs

    # Directory checks
    if [ "${directory}" = "" ]; then
        fail "No asset directory was provided for HashiCorp release"
    fi
    if [ ! -d "${directory}" ]; then
        fail "Asset directory for HashiCorp release does not exist (${directory})"
    fi

    # SHASUMS checks
    sums=("${directory}/"*SHA256SUMS)
    if [ ${#sums[@]} -lt 1 ]; then
        fail "Asset directory is missing SHASUMS file"
    fi
    sigs=("${directory}/"*SHA256SUMS.sig)
    if [ ${#sigs[@]} -lt 1 ]; then
        fail "Asset directory is missing SHASUMS signature file"
    fi
}

# Verify release assets by validating checksum properly match
# and that signature file is valid
#
# $1: Asset directory
function hashicorp_release_verify() {
    local directory="${1}"
    local gpghome

    pushd "${directory}"

    # First do a checksum validation
    wrap shasum -a 256 -c ./*_SHA256SUMS \
         "Checksum validation of release assets failed"
    # Next check that the signature is valid
    gpghome=$(mktemp -qd)
    export GNUPGHOME="${gpghome}"
    wrap gpg --keyserver keyserver.ubuntu.com --recv "${HASHICORP_PUBLIC_GPG_KEY_ID}" \
         "Failed to import HashiCorp public GPG key"
    wrap gpg --verify ./*SHA256SUMS.sig ./*SHA256SUMS \
         "Validation of SHA256SUMS signature failed"
    rm -rf "${gpghome}" > "${output}" 2>&1
    popd
}

# Generate releases-api metadata
#
# $1: Product Version
# $2: Asset directory
function generate_release_metadata() {
    local version="${1}"
    local directory="${2}"

    if ! command -v bob; then
        install_hashicorp_tool "bob"
    fi

    local hc_releases_input_metadata="input-meta.json"
    # The '-metadata-file' flag expects valid json. Contents are not used for Vagrant.
    echo "{}" > "${hc_releases_input_metadata}"

    echo -n "Generating release metadata... "
    wrap_stream bob generate-release-metadata \
                -metadata-file "${hc_releases_input_metadata}" \
                -in-dir "${directory}" \
                -version "${version}" \
                -out-file "${hc_releases_metadata_filename}" \
                "Failed to generate release metadata"
    echo "complete!"
    
    rm -f "${hc_releases_input_metadata}"
}



# Upload release metadata and assets to the staging api
#
# $1: Product Name (e.g. "vagrant")
# $2: Product Version
# $3: Asset directory
function upload_to_staging() {
    local product="${1}"
    local version="${2}"
    local directory="${3}"

    if ! command -v "hc-releases-api"; then
        install_hashicorp_tool "releases-api"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_STAGING_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_STAGING_KEY}"

    pushd "${directory}"

    # Create -file parameter list for hc-releases upload
    local fileParams=""
    for file in *; do
        fileParams="-file=${file} ${fileParams}"
    done

    echo -n "Uploading release assets... "

    # shellcheck disable=SC2086
    # NOTE: Do not quote ${fileParams}, it will expand to
    #       multiple -file parameters
    wrap_stream hc-releases-api upload \
        -product "${product}" \
        -version "${version}" \
        ${fileParams} \
        "Failed to upload HashiCorp release assets"

    echo "complete!"
    popd

    echo -n "Creating release metadata... "

    wrap_stream hc-releases-api metadata create \
        -product "${product}" \
        -input "${hc_releases_metadata_filename}" \
        "Failed to create metadata for HashiCorp release"

    echo "complete!"

    unset HC_RELEASES_HOST
    unset HC_RELEASES_KEY
}

# Promote release from staging to production
#
# $1: Product Name (e.g. "vagrant")
# $2: Product Version
function promote_to_production() {
    local product="${1}"
    local version="${2}"

    if ! command -v "hc-releases-api"; then
        install_hashicorp_tool "releases-api"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_PROD_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_PROD_KEY}"
    export HC_RELEASES_SOURCE_ENV_KEY="${HC_RELEASES_STAGING_KEY}"

    echo -n "Promoting release to production... "

    wrap_stream hc-releases-api promote \
                -product "${product}" \
                -version "${version}" \
                -source-env staging \
                "Failed to promote HashiCorp release to Production"

    echo "complete!"

    unset HC_RELEASES_HOST
    unset HC_RELEASES_KEY
    unset HC_RELEASES_SOURCE_ENV_KEY
}

# Send the post-publish sns message
#
# $1: Product name (e.g. "vagrant") defaults to $repo_name
# $2: AWS Region of SNS (defaults to us-east-1)
function sns_publish() {
    local oid
    local okey
    local otok
    local orol
    local oexp
    local message

    local product="${1}"
    local region="${2}"

    if [ -z "${product}" ]; then
        product="${repo_name}"
    fi

    if [ -z "${region}" ]; then
        region="us-east-1"
    fi

    if [ -n "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        oid="${AWS_ACCESS_KEY_ID}"
        okey="${AWS_SECRET_ACCESS_KEY}"
        otok="${AWS_SESSION_TOKEN}"
        orol="${AWS_ASSUME_ROLE_ARN}"
        oexp="${AWS_SESSION_EXPIRATION}"
        unset AWS_SESSION_TOKEN
        unset AWS_SESSION_EXPIRATION
        # This is basically a no-op to force our AWS wrapper to
        # run and do the whole session setup dance
        export AWS_ASSUME_ROLE_ARN="${RELEASE_AWS_ASSUME_ROLE_ARN}"
        export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"
        wrap aws configure list \
             "Failed to reconfigure AWS credentials for release"
    else
        oid="${AWS_ACCESS_KEY_ID}"
        okey="${AWS_SECRET_ACCESS_KEY}"
        export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"
        export AWS_REGION="${region}"
    fi

    echo -n "Sending notification to update package repositories... "
    message=$(jq --null-input --arg product "$product" '{"product": $product}')
    wrap_stream aws sns publish --region "${region}" --topic-arn "${HC_RELEASES_PROD_SNS_TOPIC}" --message "${message}" \
        "Failed to send SNS message for package repository update"
    echo "complete!"

    export AWS_ACCESS_KEY_ID="${oid}"
    export AWS_SECRET_ACCESS_KEY="${okey}"

    if [ -z "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        export AWS_ASSUME_ROLE_ARN="${orol}"
        export AWS_SESSION_TOKEN="${otok}"
        export AWS_SESSION_EXPIRATION="${oexp}"
    fi

    return 0
}

# Check if a release for the given version
# has been published to the HashiCorp
# releases site.
#
# $1: Product Name
# $2: Product Version
function hashicorp_release_exists() {
    local product="${1}"
    local version="${2}"

    echo -n "Checking for existing release of ${product}@${version}... "
    if curl --silent --fail --head "https://releases.hashicorp.com/${product}/${version}" ; then
        echo "Found!"
        return 0
    fi
    echo "not found"
    return 1
}

# Generate the SHA256SUMS file for assets
# in a given directory.
#
# $1: Asset Directory
# $2: Product Name
# $3: Product Version
function generate_shasums() {
    local directory="${1}"
    local product="${2}"
    local version="${3}"

    pushd "${directory}"

    echo -n "Generating shasums file... "
    if shasum -a256 ./* > "${product}_${version}_SHA256SUMS"; then
        echo "complete"
        popd
        return 0
    fi
    echo "failed!"
    popd
    fail "Failed to generate shasums for ${product}"
}

# Generate a HashiCorp releases-api compatible release
#
# $1: Asset directory
# $2: Product Name (e.g. "vagrant")
# $3: Product Version
function hashicorp_release() {
    local directory="${1}"
    local product="${2}"
    local version="${3}"

    # If the version is provided, use the discovered release version
    if [[ "${version}" == "" ]]; then
        version="${release_version}"
    fi

    if ! hashicorp_release_exists "${product}" "${version}"; then
        # Jump into our artifact directory
        pushd "${directory}"

        # If any sig files happen to have been included in here,
        # just remove them as they won't be using the correct
        # signing key
        rm -f ./*.sig

        # Generate our shasums file
        generate_shasums ./ "${product}" "${version}"

        # Grab the shasums file and sign it
        shasum_file=(./*SHA256SUMS)
        sign_file "${shasum_file[0]}"

        # Jump back out of our artifact directory
        popd

        # Run validation and verification on release assets before
        # we actually do the release.
        hashicorp_release_validate "${directory}"
        hashicorp_release_verify "${directory}"

        # Now that the assets have been validated and verified,
        # peform the release setps
        generate_release_metadata "${version}" "${directory}"
        upload_to_staging "${product}" "${version}" "${directory}"
        promote_to_production "${product}" "${version}"
    fi

    # Send a notification to update the package repositories
    # with the new release.
    sns_publish "${product}"
}

# Generate a HashiCorp release
#
# $1: Asset directory
# $2: Product name (e.g. "vagrant") defaults to $repo_name
function hashicorp_legacy_release() {
    directory="${1}"
    product="${2}"

    if [ -z "${product}" ]; then
        product="${repo_name}"
    fi

    hashicorp_release_validate "${directory}"
    hashicorp_release_verify "${directory}"

    if [ -n "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        oid="${AWS_ACCESS_KEY_ID}"
        okey="${AWS_SECRET_ACCESS_KEY}"
        otok="${AWS_SESSION_TOKEN}"
        orol="${AWS_ASSUME_ROLE_ARN}"
        oexp="${AWS_SESSION_EXPIRATION}"
        unset AWS_SESSION_TOKEN
        unset AWS_SESSION_EXPIRATION
        # This is basically a no-op to force our AWS wrapper to
        # run and do the whole session setup dance
        export AWS_ASSUME_ROLE_ARN="${RELEASE_AWS_ASSUME_ROLE_ARN}"
        export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"
        wrap aws configure list \
             "Failed to reconfigure AWS credentials for release"
    else
        oid="${AWS_ACCESS_KEY_ID}"
        okey="${AWS_SECRET_ACCESS_KEY}"
        export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
        export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"
    fi

    wrap_stream hc-releases upload "${directory}" \
                "Failed to upload HashiCorp release assets"
    wrap_stream hc-releases publish -product="${product}" \
                "Failed to publish HashiCorp release"

    export AWS_ACCESS_KEY_ID="${oid}"
    export AWS_SECRET_ACCESS_KEY="${okey}"

    if [ -z "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        export AWS_ASSUME_ROLE_ARN="${orol}"
        export AWS_SESSION_TOKEN="${otok}"
        export AWS_SESSION_EXPIRATION="${oexp}"
    fi

    return 0
}

# Check if gem version is already published to RubyGems
#
# $1: Name of RubyGem
# $2: Verision of RubyGem
function is_version_on_rubygems() {
    local name="${1}"
    local version="${2}"
    local result

    result="$(gem search --remote --exact --all "${name}")" ||
        fail "Failed to retreive remote version list from RubyGems"
    local versions="${result##*\(}"
    local versions="${versions%%)*}"
    local oifs="${IFS}"
    IFS=', '
    local r=1
    for v in $versions; do
        if [ "${v}" = "${version}" ]; then
            r=0
            break
        fi
    done
    IFS="${oifs}"
    return $r
}

# Build and release project gem to RubyGems
function publish_to_rubygems() {
    if [ -z "${RUBYGEMS_API_KEY}" ]; then
        fail "RUBYGEMS_API_KEY is currently unset"
    fi

    local gem_config
    local result

    gem_config="$(mktemp -p ./)" || fail "Failed to create temporary credential file"
    wrap gem build ./*.gemspec \
         "Failed to build RubyGem"
    printf -- "---\n:rubygems_api_key: %s\n" "${RUBYGEMS_API_KEY}" > "${gem_config}"
    wrap_raw gem push --config-file "${gem_config}" ./*.gem
    result=$?
    rm -f "${gem_config}"

    if [ $result -ne 0 ]; then
        fail "Failed to publish RubyGem"
    fi
}

# Publish gem to the hashigems repository
#
# $1: Path to gem file to publish
function publish_to_hashigems() {
    local path="${1}"
    if [ -z "${path}" ]; then
        fail "Path to built gem required for publishing to hashigems"
    fi

    # Define all the variables we'll need
    local user_bin
    local reaper
    local tmpdir
    local invalid
    local invalid_id

    wrap_stream gem install --user-install --no-document reaper-man \
                "Failed to install dependency for hashigem generation"
    user_bin="$(ruby -e 'puts Gem.user_dir')/bin"
    reaper="${user_bin}/reaper-man"

    # Create a temporary directory to work from
    tmpdir="$(mktemp -d -p ./)" ||
        fail "Failed to create working directory for hashigems publish"
    mkdir -p "${tmpdir}/hashigems/gems"
    wrap cp "${path}" "${tmpdir}/hashigems/gems" \
         "Failed to copy gem to working directory"
    pushd "${tmpdir}"

    # Run quick test to ensure bucket is accessible
    wrap aws s3 ls "${HASHIGEMS_METADATA_BUCKET}" \
         "Failed to access hashigems asset bucket"

    # Grab our remote metadata. If the file doesn't exist, that is always an error.
    wrap aws s3 cp "${HASHIGEMS_METADATA_BUCKET}/vagrant-rubygems.list" ./ \
         "Failed to retrieve hashigems metadata list"

    # Add the new gem to the metadata file
    wrap_stream "${reaper}" package add -S rubygems -p vagrant-rubygems.list ./hashigems/gems/*.gem \
                "Failed to add new gem to hashigems metadata list"
    # Generate the repository
    wrap_stream "${reaper}" repo generate -p vagrant-rubygems.list -o hashigems -S rubygems \
                "Failed to generate the hashigems repository"
    # Upload the updated repository
    pushd ./hashigems
    wrap_stream aws s3 sync . "${HASHIGEMS_PUBLIC_BUCKET}" \
                "Failed to upload the hashigems repository"
    # Store the updated metadata
    popd
    wrap_stream aws s3 cp vagrant-rubygems.list "${HASHIGEMS_METADATA_BUCKET}/vagrant-rubygems.list" \
                "Failed to upload the updated hashigems metadata file"

    # Invalidate cloudfront so the new content is available
    invalid="$(aws cloudfront create-invalidation --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --paths "/*")" ||
        fail "Invalidation of hashigems CDN distribution failed"
    invalid_id="$(printf '%s' "${invalid}" | jq -r ".Invalidation.Id")"
    if [ -z "${invalid_id}" ]; then
        fail "Failed to determine the ID of the hashigems CDN invalidation request"
    fi

    # Wait for the invalidation process to complete
    wrap aws cloudfront wait invalidation-completed --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --id "${invalid_id}" \
         "Failure encountered while waiting for hashigems CDN invalidation request to complete (ID: ${invalid_id})"

    # Clean up and we are done
    popd
    rm -rf "${tmpdir}"
}

# Configures git for hashibot usage
function hashibot_git() {
    wrap git config user.name "${HASHIBOT_USERNAME}" \
         "Failed to setup git for hashibot usage (username)"
    wrap git config user.email "${HASHIBOT_EMAIL}" \
         "Failed to setup git for hashibot usage (email)"
    wrap git remote set-url origin "https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com/${repository}" \
         "Failed to setup git for hashibot usage (remote)"
}

# Get the default branch name for the current repository
function default_branch() {
    local s
    s="$(git symbolic-ref refs/remotes/origin/HEAD)" ||
        fail "Failed to determine default branch (is working directory git repository?)"
    echo -n "${s##*origin/}"
}

# Loads signing files for packaging. The return value can be eval'd
# to set expected environment variables for packet-exec to use.
function load-signing() {
    local secrets key result
    declare -A secrets=(
        ["MACOS_PACKAGE_CERT"]="./MacOS_PackageSigning.cert.gpg"
        ["MACOS_PACKAGE_KEY"]="./MacOS_PackageSigning.key.gpg"
        ["MACOS_CODE_CERT"]="./MacOS_CodeSigning.p12.gpg"
        ["WIN_SIGNING_KEY"]="./Win_CodeSigning.p12.gpg"
    )

    for key in "${!secrets[@]}"; do
        local local_path="${secrets[${key}]}"
        local var_name="PKT_SECRET_FILE_${key}"
        local content_variable="${key}_CONTENT"

        # Content will be encoded so first we decode
        local content
        content="$(base64 --decode - <<< "${!content_variable}")" ||
            fail "Failed to decode secret file content"
        # Now we save it into the expected file
        printf "%s" "${content}" > "${local_path}"

        result+="export ${var_name}=\"${local_path}\"\n"
    done

    printf "%b" "${result}"
}

# Send a notification to slack. All flag values can be set with
# environment variables using the upcased name prefixed with SLACK_,
# for example: --channel -> SLACK_CHANNEL
#
# -c --channel CHAN        Send to channel
# -u --username USER       Send as username
# -i --icon URL            User icon image
# -s --state STATE         Message state (success, warn, error, or color code)
# -m --message MESSAGE     Message to send
# -M --message-file PATH   Use file contents as message
# -f --file PATH           Send raw contents of file in message (displayed in code block)
# -t --title TITLE         Message title
# -T --tail NUMBER         Send last NUMBER lines of content from raw message file
# -w --webhook URL         Slack webhook
function slack() {
    # Convert any long names to short names
    for arg in "$@"; do
        shift
        case "${arg}" in
            "--channel") set -- "${@}" "-c" ;;
            "--username") set -- "${@}" "-u" ;;
            "--icon") set -- "${@}" "-i" ;;
            "--state") set -- "${@}" "-s" ;;
            "--message") set -- "${@}" "-m" ;;
            "--message-file") set -- "${@}" "-M" ;;
            "--file") set -- "${@}" "-f" ;;
            "--title") set -- "${@}" "-t" ;;
            "--tail") set -- "${@}" "-T" ;;
            "--webhook") set -- "${@}" "-w"  ;;
            *) set -- "${@}" "${arg}" ;;
        esac
    done
    local OPTIND opt
    # Default all options to values provided by environment variables
    local channel="${SLACK_CHANNEL}"
    local username="${SLACK_USERNAME}"
    local icon="${SLACK_ICON}"
    local state="${SLACK_STATE}"
    local message="${SLACK_MESSAGE}"
    local message_file="${SLACK_MESSAGE_FILE}"
    local file="${SLACK_FILE}"
    local title="${SLACK_TITLE}"
    local tail="${SLACK_TAIL}"
    local webhook="${SLACK_WEBHOOK}"
    while getopts ":c:u:i:s:m:M:f:t:T:w:" opt; do
        case "${opt}" in
            "c") channel="${OPTARG}" ;;
            "u") username="${OPTARG}" ;;
            "i") icon="${OPTARG}" ;;
            "s") state="${OPTARG}" ;;
            "m") message="${OPTARG}" ;;
            "M") message_file="${OPTARG}" ;;
            "f") file="${OPTARG}" ;;
            "t") title="${OPTARG}" ;;
            "T") tail="${OPTARG}" ;;
            "w") webhook="${OPTARG}" ;;
            *) fail "Invalid flag provided to slack" ;;
        esac
    done
    shift $((OPTIND-1))

    local footer footer_icon ts

    # If we are using GitHub actions, format the footer
    if [ -n "${GITHUB_ACTIONS}" ]; then
        if [ -z "${icon}" ]; then
            icon="https://ca.slack-edge.com/T024UT03C-WG8NDATGT-f82ae03b9fca-48"
        fi
        if [ -z "${username}" ]; then
            username="GitHub"
        fi
        footer_icon="https://ca.slack-edge.com/T024UT03C-WG8NDATGT-f82ae03b9fca-48"
        footer="Actions - <https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}/checks|${GITHUB_REPOSITORY}>"
    fi

    # If no state was provided, default to good state
    if [ -z "${state}" ]; then
        state="good"
    fi

    # Convert state aliases
    case "${state}" in
        "success" | "good")
            state="good";;
        "warn" | "warning")
            state="warning";;
        "error" | "danger")
            state="danger";;
    esac

    # If we have a message file, read it
    if [ -n "${message_file}" ]; then
        local message_file_content
        message_file_content="$(<"${message_file}")"
        if [ -z "${message}" ]; then
            message="${message_file_content}"
        else
            message="${message}\n\n${message_file_content}"
        fi
    fi

    # If we have a file to include, add it now. Files are
    # displayed as raw content, so be sure to wrap with
    # backticks
    if [ -n "${file}" ]; then
        local file_content
        # If tail is provided, then only include the last n number
        # of lines in the file
        if [ -n "${tail}" ]; then
            if ! file_content="$(tail -n "${tail}" "${file}")"; then
                file_content="UNEXPECTED ERROR: Failed to tail content in file ${file}"
            fi
        else
            file_content="$(<"${file}")"
        fi
        message="${message}\n\n\`\`\`\n${file_content}\n\`\`\`"
    fi

    local attach attach_template payload payload_template ts
    ts="$(date '+%s')"

    # shellcheck disable=SC2016
    attach_template='{text: $msg, fallback: $msg, color: $state, mrkdn: true, ts: $time'
    if [ -n "${title}" ]; then
        # shellcheck disable=SC2016
        attach_template+=', title: $title'
    fi
    if [ -n "${footer}" ]; then
        # shellcheck disable=SC2016
        attach_template+=', footer: $footer'
    fi
    if [ -n "${footer_icon}" ]; then
        # shellcheck disable=SC2016
        attach_template+=', footer_icon: $footer_icon'
    fi
    attach_template+='}'

    attach=$(jq -n \
        --arg msg "$(printf "%b" "${message}")" \
        --arg title "${title}" \
        --arg state "${state}" \
        --arg time "${ts}" \
        --arg footer "${footer}" \
        --arg footer_icon "${footer_icon}" \
        "${attach_template}" \
        )

    # shellcheck disable=SC2016
    payload_template='{attachments: [$attachment]'
    if [ -n "${username}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', username: $username'
    fi
    if [ -n "${channel}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', channel: $channel'
    fi
    if [ -n "${icon}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', icon_url: $icon'
    fi
    payload_template+='}'

    payload=$(jq -n \
        --argjson attachment "${attach}" \
        --arg username "${username}" \
        --arg channel "${channel}" \
        --arg icon "${icon}" \
        "${payload_template}" \
        )

    if ! curl -SsL --fail -X POST -H "Content-Type: application/json" -d "${payload}" "${webhook}"; then
        echo "ERROR: Failed to send slack notification"
    fi
}

# Install internal HashiCorp tools. These tools are expected to
# be located in private (though not required) HashiCorp repositories
# and provide their binary in a zip file with an extension of:
#
#  linux_amd64.zip
#
# $1: Name of repository
function install_hashicorp_tool() {
    local tool_name="${1}"
    local asset release_content tmp

    tmp="$(mktemp -d --tmpdir vagrantci-XXXXXX)" ||
        fail "Failed to create temporary working directory"
    pushd "${tmp}"

    if [ -z "${HASHIBOT_TOKEN}" ]; then
        fail "HASHIBOT_TOKEN is required for internal tool install"
    fi

    release_content=$(curl -SsL --fail -H "Authorization: token ${HASHIBOT_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/hashicorp/${tool_name}/releases/latest") ||
        fail "Failed to request latest releases for hashicorp/${tool_name}"

    asset=$(printf "%s" "${release_content}" | jq -r \
        '.assets[] | select(.name | contains("linux_amd64.zip")) | .url') ||
        fail "Failed to detect latest release for hashicorp/${tool_name}"

    wrap curl -SsL --fail -o "${tool_name}.zip" -H "Authorization: token ${HASHIBOT_TOKEN}" \
        -H "Accept: application/octet-stream" "${asset}" \
        "Failed to download latest release for hashicorp/${tool_name}"

    wrap unzip "${tool_name}.zip" \
        "Failed to unpack latest release for hashicorp/${tool_name}"

    rm -f "${tool_name}.zip"

    wrap chmod 0755 ./* \
        "Failed to change mode on latest release for hashicorp/${tool_name}"

    wrap mv ./* "${ci_bin_dir}" \
        "Failed to install latest release for hashicorp/${tool_name}"

    popd
    rm -rf "${tmp}"
}

# Install tool from GitHub releases. It will fetch the latest release
# of the tool and install it. The proper release artifact will be matched
# by a "linux_amd64" string. This command is best effort and may not work.
#
# $1: Organization name
# $2: Repository name
#
function install_github_tool() {
    local org_name="${1}"
    local tool_name="${2}"
    local asset release_content tmp
    local artifact_list artifact basen

    tmp="$(mktemp -d --tmpdir vagrantci-XXXXXX)" ||
        fail "Failed to create temporary working directory"
    pushd "${tmp}"

    release_content=$(curl -SsL --fail \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${org_name}/${tool_name}/releases/latest") ||
        fail "Failed to request latest releases for ${org_name}/${tool_name}"

    asset=$(printf "%s" "${release_content}" | jq -r \
        '.assets[] | select(.name | contains("linux_amd64")) | .url') ||
        fail "Failed to detect latest release for ${org_name}/${tool_name}"

    artifact="${asset##*/}"
    wrap curl -SsL --fail -o "${artifact}" \
        -H "Accept: application/octet-stream" "${asset}" \
        "Failed to download latest release for ${org_name}/${tool_name}"

    basen="${artifact##*.}"
    if [ "${basen}" = "zip" ]; then
        wrap unzip "${artifact}" \
            "Failed to unpack latest release for ${org_name}/${tool_name}"
        rm -f "${artifact}"
    elif [ -n "${basen}" ]; then
        wrap tar xf "${artifact}" \
            "Failed to unpack latest release for ${org_name}/${tool_name}"
        rm -f "${artifact}"
    fi

    artifact_list=(./*)
    artifact="$(printf "%s" "${artifact_list[0]}")"

    # If the artifact is a directory, see if the tool_name is inside
    if [ -d "${artifact}" ]; then
        if [ -f "${artifact}/${tool_name}" ]; then
            mv "${artifact}/${tool_name}" ./
            rm -rf "${artifact}"
            artifact="${tool_name}"
        else
            fail "Failed to locate executable in package directory for ${org_name}/${tool_name}"
        fi
    fi

    # If the tool includes platform/arch information, just
    # rename to the tool_name
    if [[ "${artifact}" = *"linux"* ]] || [[ "${artifact}" = *"amd64"* ]]; then
        mv "${artifact}" "${tool_name}"
    fi

    wrap chmod 0755 ./* \
        "Failed to change mode on latest release for ${org_name}/${tool_name}"

    wrap mv ./* "${ci_bin_dir}" \
        "Failed to install latest release for ${org_name}/${tool_name}"

    popd
    rm -rf "${tmp}"
}

# Simple helper to install ghr
function install_ghr() {
    install_github_tool "tcnksm" "ghr"
}

# Prepare host for packet use. It will validate the
# required environment variables are set, ensure
# packet-exec is installed, and setup the SSH key.
function packet-setup() {
    # First check that we have the environment variables
    if [ -z "${PACKET_EXEC_TOKEN}" ]; then
        fail "Cannot setup packet, missing token"
    fi
    if [ -z "${PACKET_EXEC_PROJECT_ID}" ]; then
        fail "Cannot setup packet, missing project"
    fi
    if [ -z "${PACKET_SSH_KEY_CONTENT}" ]; then
        fail "Cannot setup packet, missing ssh key"
    fi

    install_hashicorp_tool "packet-exec"

    # Write the ssh key to disk
    local content
    content="$(base64 --decode - <<< "${PACKET_SSH_KEY_CONTENT}")" ||
        fail "Cannot setup packet, failed to decode key"
    touch ./packet-key
    chmod 0600 ./packet-key
    printf "%s" "${content}" > ./packet-key
    local working_directory
    working_directory="$(pwd)" ||
        fail "Cannot setup packet, failed to determine working directory"
    export PACKET_EXEC_SSH_KEY="${working_directory}/packet-key"
}

# Download artifact(s) from GitHub release. The artifact pattern is simply
# a substring that is matched against the artifact download URL. Artifact(s)
# will be downloaded to the working directory.
#
# $1: organization name
# $2: repository name
# $3: release tag name
# $4: artifact pattern (optional, all artifacts downloaded if omitted)
function github_release_assets() {
    local release_repo release_name asset_pattern release_content
    release_repo="${1}/${2}"
    release_name="${3}"
    asset_pattern="${4}"

    release_content=$(curl -SsL --fail \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${release_repo}/releases/tags/${release_name}") ||
        fail "Failed to request release (${release_name}) for ${release_repo}"

    local asset_list query artifact asset
    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi
    query+=" | .url"
    asset_list=$(printf "%s" "${release_content}" | jq -r "${query}") ||
        fail "Failed to detect asset in release (${release_name}) for ${release_repo}"

    readarray -t assets <  <(printf "%s" "${asset_list}")
    # shellcheck disable=SC2066
    for asset in "${assets[@}]}"; do
        artifact="${asset##*/}"
        wrap curl -SsL --fail -o "${artifact}" \
            -H "Accept: application/octet-stream" "${asset}" \
            "Failed to download asset in release (${release_name}) for ${release_repo}"
    done
}

# Download artifact(s) from GitHub draft release. A draft release is not
# attached to a tag and therefore is referenced by the release name directly.
# The artifact pattern is simply a substring that is matched against the
# artifact download URL. Artifact(s) will be downloaded to the working directory.
# NOTE: We only fetch at most 100 releases and don't loop to subsequent pages
#       if release is not found. This is because I'm lazy and don't want to
#       write the ugly bash to do it, but if it becomes a problem we can add
#       it in later.
#
# $1: organization name
# $2: repository name
# $3: release name
# $4: artifact pattern (optional, all artifacts downloaded if omitted)
function github_draft_release_assets() {
    local release_list release_repo release_name asset_pattern release_content
    release_repo="${1}/${2}"
    release_name="${3}"
    asset_pattern="${4}"

    release_list=$(curl -SsL --fail \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${release_repo}/releases?per_page=100") ||
        fail "Failed to request releases list for ${release_repo}"

    local asset_list query artifact asset
    query="$(printf '.[] | select(.name == "%s")' "${release_name}")"
    release_content=$(printf "%s" "${release_list}" | jq -r "${query}") ||
        fail "Failed to find release (${release_name}) in releases list for ${release_repo}"

    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi
    query+=" | .url"
    asset_list=$(printf "%s" "${release_content}" | jq -r "${query}") ||
        fail "Failed to detect asset in release (${release_name}) for ${release_repo}"

    readarray -t assets <  <(printf "%s" "${asset_list}")
    # shellcheck disable=SC2066
    for asset in "${assets[@]}"; do
        artifact="${asset##*/}"
        wrap curl -SsL --fail -o "${artifact}" \
            -H "Accept: application/octet-stream" "${asset}" \
            "Failed to download asset in release (${release_name}) for ${release_repo}"
    done
}

# Send a repository dispatch to the defined repository
#
# $1: organization name
# $2: repository name
# $3: event type (single word string)
# $n: "key=value" pairs to build payload (optional)
function github_repository_dispatch() {
    if [ -z "${HASHIBOT_TOKEN}" ] || [ -z "${HASHIBOT_USERNAME}" ]; then
        fail "Repository dispatch requires hashibot configuration"
    fi

    local arg payload_key payload_value jqargs payload \
        msg_template msg dorg_name drepo_name event_type

    dorg_name="${1}"
    drepo_name="${2}"
    event_type="${3}"

    # shellcheck disable=SC2016
    payload_template='{vagrant-ci: $vagrant_ci'
    jqargs="--arg vagrant_ci true"
    for arg in "${@:4}"; do
        payload_key="${arg%%=*}"
        payload_value="${arg##*=}"
        payload_template=", ${payload_key}: \$${payload_key}"
        jqargs+=" --arg \$${payload_key} \"${payload_value}\""
    done
    payload_template="}"

    payload=$(jq -n "${jqargs}" "${payload_template}" ) ||
        fail "Failed to generate repository dispatch payload"

    # shellcheck disable=SC2016
    msg_template='{event_type: $event_type, client_payload: $payload}'
    msg=$(jq -n \
        --argjson payload "${payload}" \
        --arg event_type "${event_type}" \
        "${msg_template}" \
        ) || fail "Failed to generate repository dispatch message"

    wrap curl -SsL --fail -X POST "https://api.github.com/repos/${dorg_name}/${drepo_name}/dispatches" \
        -H 'Accept: application/vnd.github.everest-v3+json' \
        -u "${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}" \
        --data "${msg}" \
        "Repository dispatch to ${dorg_name}/${drepo_name} failed"
}

# Stub cleanup method which can be redefined
# within actual script
function cleanup() {
    (>&2 echo "** No cleanup tasks defined")
}

trap cleanup EXIT

# Make sure the CI bin directory exists
if [ ! -d "${ci_bin_dir}" ]; then
    wrap mkdir -p "${ci_bin_dir}" \
        "Failed to create CI bin directory"
fi

# Always ensure CI bin directory is in PATH
if [[ "${PATH}" != *"${ci_bin_dir}"* ]]; then
    export PATH="${PATH}:${ci_bin_dir}"
fi

# If the bash version isn't at least 4, bail
[ "${BASH_VERSINFO:-0}" -ge "4" ] || fail "Expected bash version >= 4 (is: ${BASH_VERSINFO:-0})"

# Enable debugging. This needs to be enabled with
# extreme caution when used on public repositories.
# Output with debugging enabled will likely include
# secret values which should not be publicly exposed.
#
# If repository is public, FORCE_PUBLIC_DEBUG environment
# variable must also be set.

# If we have a token, we can run the actual check for
# repository visibility. If we don't, then default
# the is_private value to false.
if [ -n "${HASHIBOT_TOKEN}" ]; then
    is_private=$(curl -H "Authorization: token ${HASHIBOT_TOKEN}" -s "https://api.github.com/repos/${GITHUB_REPOSITORY}" | jq .private) ||
        fail "Repository visibility check failed"
else
    is_private="false"
fi

# If we have debugging enabled, check if we are in a private
# repository. If we are, enable it. If we are not, check if
# debugging is being forced and allow it. Otherwise, return
# an error message to prevent leaking unintended information.
if [ "${DEBUG}" != "" ]; then
    if [ "${is_private}" = "false" ]; then
        if [ "${FORCE_PUBLIC_DEBUG}" != "" ]; then
            set -x
            output="/dev/stdout"
        else
            fail "Cannot enable debug mode on public repository unless forced"
        fi
    else
        set -x
        output="/dev/stdout"
    fi
else
    output="/dev/null"
fi

# Check if we are running a job created by a tag. If so,
# mark this as being a release job and set the release_version
if [[ "${GITHUB_REF}" == *"refs/tags/"* ]]; then
    export tag="${GITHUB_REF##*tags/}"
    if valid_release_version "${tag}"; then
        readonly release=1
        export release_version="${tag##*v}"
    else
        readonly release
    fi
else
    readonly release
fi
