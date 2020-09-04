# last-modified: Thu Sep  3 20:54:51 UTC 2020
#!/usr/bin/env bash

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
    printf "${ci_output_file_path}"
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
    output_file "clean"
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

# Generates location within the asset storage
# bucket to retain built assets.
function asset_location() {
    if [ ! -z "${tag}" ]; then
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
    tag_name="${1}"
    assets="${2}"
    body="$(release_details)"
    body="${body:-New ${repo_name} release - ${tag_name}}"
    wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${tag_name}" \
             -b "${body}" -delete "${assets}"
    if [ $? -ne 0 ]; then
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
    if [[ "${1}" != *"+"* ]]; then
        ptag="${1}+${short_sha}"
    else
        ptag="${1}"
    fi
    assets="${2}"

    wrap_raw ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -delete -prerelease "${ptag}" "${assets}"
    if [ $? -ne 0 ]; then
        wrap ghr -u "${repo_owner}" -r "${repo_name}" -c "${full_sha}" -n "${ptag}" \
             -prerelease "${ptag}" "${assets}" \
             "Failed to create prerelease for version ${1}"
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
    tag_name="${1}"
    proj_root="$(git rev-parse --show-toplevel)"
    if [ $? -ne 0 ] || [ -z "$(git tag -l "${tag_name}")"] || [ ! -f "${proj_root}/CHANGELOG.md" ]; then
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
    directory="${1}"

    # Directory checks
    if [ "${directory}" = "" ]; then
        fail "No asset directory was provided for HashiCorp release"
    fi
    if [ ! -d "${directory}" ]; then
        fail "Asset directory for HashiCorp release does not exist"
    fi

    # SHASUMS checks
    if [ ! -e "${directory}/"*SHA256SUMS ]; then
        fail "Asset directory is missing SHASUMS file"
    fi
    if [ ! -e "${directory}/"*SHA256SUMS.sig ]; then
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
    wrap gpg --keyserver keyserver.ubuntu.com --recv "${HASHICORP_PUBLIC_GPG_KEY_ID}" \
         "Failed to import HashiCorp public GPG key"
    wrap gpg --verify *SHA256SUMS.sig *SHA256SUMS \
         "Validation of SHA256SUMS signature failed"
    rm -rf "${gpghome}" > "${output}" 2>&1
    popd > "${output}"
}

# Generate a HashiCorp release
#
# $1: Asset directory
# $2: Product name (e.g. "vagrant") defaults to $repo_name
function hashicorp_release() {
    directory="${1}"
    product="${2}"

    if [ -z "${product}" ]; then
        product="${repo_name}"
    fi

    hashicorp_release_validate "${directory}"
    hashicorp_release_verify "${directory}"

    oid="${AWS_ACCESS_KEY_ID}"
    okey="${AWS_SECRET_ACCESS_KEY}"
    export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"

    wrap_stream hc-releases upload "${directory}" \
                "Failed to upload HashiCorp release assets"
    wrap_stream hc-releases publish -product="${product}" \
                "Failed to publish HashiCorp release"

    export AWS_ACCESS_KEY_ID="${oid}"
    export AWS_SECRET_ACCESS_KEY="${okey}"
}

# Build and release project gem to RubyGems
function publish_to_rubygems() {
    if [ -z "${RUBYGEMS_API_KEY}" ]; then
        fail "RUBYGEMS_API_KEY is currently unset"
    fi

    gem_config="$(mktemp -p ./)" || fail "Failed to create temporary credential file"
    wrap gem build *.gemspec \
         "Failed to build RubyGem"
    printf -- "---\n:rubygems_api_key: ${RUBYGEMS_API_KEY}\n" > "${gem_config}"
    wrap_raw gem push --config-file "${gem_config}" *.gem
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
    path="${1}"
    if [ -z "${path}" ]; then
        fail "Path to built gem required for publishing to hashigems"
    fi

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
    wrap_raw pushd "${tmpdir}"

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
    wrap_raw pushd ./hashigems
    wrap_stream aws s3 sync . "${HASHIGEMS_PUBLIC_BUCKET}" \
                "Failed to upload the hashigems repository"
    # Store the updated metadata
    wrap_raw popd
    wrap_stream aws s3 cp vagrant-rubygems.list "${HASHIGEMS_METADATA_BUCKET}/vagrant-rubygems.list" \
                "Failed to upload the updated hashigems metadata file"

    # Invalidate cloudfront so the new content is available
    invalid="$(aws cloudfront create-invalidation --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --paths "/*")"
    if [ $? -ne 0 ]; then
        fail "Invalidation of hashigems CDN distribution failed"
    fi
    invalid_id="$(printf '%s' "${invalid}" | jq -r ".Invalidation.Id")"
    if [ -z "${invalid_id}" ]; then
        fail "Failed to determine the ID of the hashigems CDN invalidation request"
    fi

    # Wait for the invalidation process to complete
    wrap aws cloudfront wait invalidation-completed --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --id "${invalid_id}" \
         "Failure encountered while waiting for hashigems CDN invalidation request to complete (ID: ${invalid_id})"

    # Clean up and we are done
    wrap_raw popd
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
run_number="${GITHUB_RUN_NUMBER}"
run_id="${GITHUB_RUN_ID}"
job_id="${run_id}-${run_number}"
