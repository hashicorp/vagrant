# last-modified: Tue Jan 14 20:37:58 UTC 2020
#!/usr/bin/env bash

# Path to file used for output redirect
# and extracting messages for warning and
# failure information sent to slack
function output_file() {
    printf "/tmp/.ci-output"
}

# Write failure message, send error to configured
# slack, and exit with non-zero status. If an
# "$(output_file)" file exists, the last 5 lines will be
# included in the slack message.
#
# $1: Failure message
function fail() {
    (>&2 echo "ERROR: ${1}")
    if [ -f ""$(output_file)"" ]; then
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
    if [ -f ""$(output_file)"" ]; then
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
    wrap_raw "${@:1:$i}"
    if [ $? -ne 0 ]; then
        cat "$(output_file)"
        fail "${@:$#}"
    fi
    rm "$(output_file)"
}

# Execute command while redirecting all output to
# a file. Exit status is returned.
function wrap_raw() {
    rm -f "$(output_file)"
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
    wrap_stream_raw "${@:1:$i}"
    if [ $? -ne 0 ]; then
        fail "${@:$#}"
    fi
    rm "$(output_file)"
}

# Execute command while redirecting all output
# to a file. Command output will be streamed
# during execution. Exit status is returned
function wrap_stream_raw() {
    rm -f "$(output_file)"
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

# Generates location within the asset storage
# bucket to retain built assets.
function asset_location() {
    if [ "${tag}" = "" ]; then
        dst="${ASSETS_PRIVATE_LONGTERM}/${repository}/${ident_ref}/${short_sha}"
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
    wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${1}" -delete
    if [ $? -ne 0 ]; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${1}" \
             "${1}" "${2}" "Failed to create release for version ${1}"
    fi
}

# Generate a GitHub prerelease
#
# $1: GitHub tag name
# $2: Asset file or directory of assets
function prerelease() {
    release_validate "${@}"
    if [[ "${1}" != *"+"* ]]; then
        ptag="${1}+${short_sha}"
    else
        ptag="${1}"
    fi

    wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -delete -prerelease "${ptag}" "${2}"
    if [ $? -ne 0 ]; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -prerelease "${ptag}" "${2}" \
             "Failed to create prerelease for version ${1}"
    fi
    echo -n "${ptag}"
}

# Check if version string is valid for release
#
# $1: Version
# Returns: 0 if valid, 1 if invalid
function valid_release_version() {
    if [[ "${1}" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
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
    directory="${1}"

    # Directory checks
    if [ "${directory}" = "" ]; then
        fail "No asset directory was provided for HashiCorp release"
    fi
    if [ ! -d "${directory}" ]; then
        fail "Asset directory for HashiCorp release does not exist"
    fi

    # SHASUMS checks
    if [ ! -e "${directory}/"*SHASUMS ]; then
        fail "Asset directory is missing SHASUMS file"
    fi
    if [ ! -e "${directory}/"*SHASUMS.sig ]; then
        fail "Asset directory is missing SHASUMS signature file"
    fi
}

# Verify release assets by validating checksum properly match
# and that signature file is valid
#
# $1: Asset directory
function hashicorp_release_verify() {
    directory="${1}"
    pushd "${directory}" > "${output}"

    # First do a checksum validation
    wrap shasum -a 256 -c *_SHA256SUMS \
         "Checksum validation of release assets failed"
    # Next check that the signature is valid
    gpghome=$(mktemp -qd)
    export GNUPGHOME="${gpghome}"
    wrap gpg --import "${HASHICORP_PUBLIC_GPG_KEY}" \
         "Failed to import HashiCorp public GPG key"
    wrap gpg --verify *SHA256SUMS.sig *SHA256SUMS \
         "Validation of SHA256SUMS signature failed"
    rm -rf "${gpghome}" > "${output}" 2>&1
    popd > "${output}"
}

# Generate a HashiCorp release
#
# $1: Asset directory
function hashicorp_release() {
    directory="${1}"

    hashicorp_release_validate "${directory}"
    hashicorp_release_verify "${directory}"

    oid="${AWS_ACCESS_KEY_ID}"
    okey="${AWS_SECRET_ACCESS_KEY}"
    export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"

    wrap_stream hc-releases upload "${directory}" \
                "Failed to upload HashiCorp release assets"
    wrap_stream hc-releases publish \
                "Failed to publish HashiCorp release"

    export AWS_ACCESS_KEY_ID="${oid}"
    export AWS_SECRET_ACCESS_KEY="${okey}"
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

# Stub cleanup method which can be redefined
# within actual script
function cleanup() {
    (>&2 echo "** No cleanup tasks defined")
}

trap cleanup EXIT

# Enable debugging. This needs to be enabled with
# extreme caution when used on public repositories.
# Output with debugging enabled will likely include
# secret values which should not be publicly exposed.
#
# If repository is public, FORCE_PUBLIC_DEBUG environment
# variable must also be set.

is_private=$(curl -H "Authorization: token ${HASHIBOT_TOKEN}" -s "https://api.github.com/repos/${GITHUB_REPOSITORY}" | jq .private)

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

# Check if we are running a public repository on private runners
if [ "${VAGRANT_PRIVATE}" != "" ] && [ "${is_private}" = "false" ]; then
    fail "Cannot run public repositories on private Vagrant runners. Disable runners now!"
fi

# Common variables
full_sha="${GITHUB_SHA}"
short_sha="${full_sha:0:8}"
ident_ref="${GITHUB_REF#*/*/}"
if [[ "${GITHUB_REF}" == *"refs/tags/"* ]]; then
    tag="${GITHUB_REF##*tags/}"
    valid_release_version "${tag}"
    if [ $? -eq 0 ]; then
        release=1
    fi
fi
repository="${GITHUB_REPOSITORY}"
repo_owner="${repository%/*}"
repo_name="${repository#*/}"
asset_cache="${ASSETS_PRIVATE_SHORTTERM}/${repository}/${GITHUB_ACTION}"
job_id="${GITHUB_ACTION}"
