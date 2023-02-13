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
# NOTE: This was a wrapper for the AWS command that would properly
#       handle the assume role process and and automatically refresh
#       if close to expiry. With credentials being handled by the doormat
#       action now, this is no longer needed but remains in case it's
#       needed for some reason in the future.
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
        unset ci_output_file_path
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
function failure() {
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
    (>&2 echo "WARN: ${1}")
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
        failure "${@:$#}"
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
        failure "${@:$#}"
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
    wrap command builtin pushd "${@}" "Failed to push into directory"
}

# Wrap the popd command so we fail
# if the popd command fails. Arguments
# are just passed through.
# shellcheck disable=SC2120
function popd() {
    wrap command builtin popd "${@}" "Failed to pop from directory"
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
    if [ -z "${1}" ]; then
        failure "Origin file is required for signing"
    fi

    if [ ! -f "${1}" ]; then
        failure "Origin file does not exist (${1})"
    fi

    # Validate environment has required signore variables set
    if [ -z "${SIGNORE_CLIENT_ID}" ]; then
        failure "Cannot sign file, SIGNORE_CLIENT_ID is not set"
    fi
    if [ -z "${SIGNORE_CLIENT_SECRET}" ]; then
        failure "Cannot sign file, SIGNORE_CLIENT_SECRET is not set"
    fi
    if [ -z "${SIGNORE_SIGNER}" ]; then
        failure "Cannot sign file, SIGNORE_SIGNER is not set"
    fi

    local origin="${1}"
    local destination="${2}"
    if [ -z "${destination}" ]; then
        destination="${origin}.sig"
    fi

    if ! command -v signore; then
        install_hashicorp_tool "signore"
    fi

    if [ -e "${destination}" ]; then
        failure "File already exists at signature destination path (${destination})"
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
        failure "Missing required position 1 argument (TAG) for release"
    fi
    if [ "${2}" = "" ]; then
        failure "Missing required position 2 argument (PATH) for release"
    fi
    if [ ! -e "${2}" ]; then
        failure "Path provided for release (${2}) does not exist"
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
        failure "No asset directory was provided for HashiCorp release"
    fi
    if [ ! -d "${directory}" ]; then
        failure "Asset directory for HashiCorp release does not exist (${directory})"
    fi

    # SHASUMS checks
    sums=("${directory}/"*SHA256SUMS)
    if [ ${#sums[@]} -lt 1 ]; then
        failure "Asset directory is missing SHASUMS file"
    fi
    sigs=("${directory}/"*SHA256SUMS.sig)
    if [ ${#sigs[@]} -lt 1 ]; then
        failure "Asset directory is missing SHASUMS signature file"
    fi
}

# Verify release assets by validating checksum properly match
# and that signature file is valid
#
# $1: Asset directory
function hashicorp_release_verify() {
    if [ -z "${HASHICORP_PUBLIC_GPG_KEY_ID}" ]; then
        failure "Cannot verify release without GPG key ID. Set HASHICORP_PUBLIC_GPG_KEY_ID."
    fi

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

    if ! command -v "hc-releases"; then
        install_hashicorp_tool "releases-api"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_STAGING_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_STAGING_KEY}"

    pushd "${directory}"

    # Create -file parameter list for hc-releases upload
    local fileParams=()
    for file in *; do
        fileParams+=("-file=${file}")
    done

    echo -n "Uploading release assets... "

    wrap_stream hc-releases upload \
        -product "${product}" \
        -version "${version}" \
        "${fileParams[@]}" \
        "Failed to upload HashiCorp release assets"

    echo "complete!"
    popd

    echo -n "Creating release metadata... "

    wrap_stream hc-releases metadata create \
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

    if ! command -v "hc-releases"; then
        install_hashicorp_tool "releases-api"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_PROD_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_PROD_KEY}"
    export HC_RELEASES_SOURCE_ENV_KEY="${HC_RELEASES_STAGING_KEY}"

    echo -n "Promoting release to production... "

    wrap_stream hc-releases promote \
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
    local message
    local product="${1}"
    local region="${2}"

    if [ -z "${RELEASE_AWS_ACCESS_KEY_ID}" ]; then
        failure "Missing AWS access key ID for SNS publish"
    fi

    if [ -z "${RELEASE_AWS_SECRET_ACCESS_KEY}" ]; then
        failure "Missing AWS access key for SNS publish"
    fi

    if [ -z "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        failure "Missing AWS role ARN for SNS publish"
    fi

    if [ -z "${product}" ]; then
        product="${repo_name}"
    fi

    if [ -z "${region}" ]; then
        region="us-east-1"
    fi

    local core_id core_key old_id old_key old_token old_role old_expiration old_region
    if [ -n "${AWS_ACCESS_KEY_ID}" ]; then
        # Store current credentials to be restored
        core_id="${CORE_AWS_ACCESS_KEY_ID}"
        core_key="${CORE_AWS_SECRET_ACCESS_KEY}"
        old_id="${AWS_ACCESS_KEY_ID}"
        old_key="${AWS_SECRET_ACCESS_KEY}"
        old_token="${AWS_SESSION_TOKEN}"
        old_role="${AWS_ASSUME_ROLE_ARN}"
        old_expiration="${AWS_SESSION_EXPIRATION}"
        old_region="${AWS_REGION}"
        unset AWS_SESSION_TOKEN
    fi

    export AWS_ACCESS_KEY_ID="${RELEASE_AWS_ACCESS_KEY_ID}"
    export AWS_SECRET_ACCESS_KEY="${RELEASE_AWS_SECRET_ACCESS_KEY}"
    export AWS_ASSUME_ROLE_ARN="${RELEASE_AWS_ASSUME_ROLE_ARN}"
    export AWS_REGION="${region}"

    # Validate the creds properly assume role and function
    wrap aws configure list \
        "Failed to reconfigure AWS credentials for release notification"

    # Now send the release notification
    echo "Sending notification to update package repositories... "
    message=$(jq --null-input --arg product "$product" '{"product": $product}')
    wrap_stream aws sns publish --region "${region}" --topic-arn "${HC_RELEASES_PROD_SNS_TOPIC}" --message "${message}" \
        "Failed to send SNS message for package repository update"
    echo "complete!"

    # Before we finish restore the previously set credentials if we unset them
    if [ -n "${core_id}" ]; then
        export CORE_AWS_ACCESS_KEY_ID="${core_id}"
        export CORE_AWS_SECRET_ACCESS_KEY="${core_key}"
        export AWS_ACCESS_KEY_ID="${old_id}"
        export AWS_SECRET_ACCESS_KEY="${old_key}"
        export AWS_SESSION_TOKEN="${old_token}"
        export AWS_ASSUME_ROLE_ARN="${old_role}"
        export AWS_SESSION_EXPIRATION="${old_expiration}"
        export AWS_REGION="${old_region}"
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

    local shacontent
    shacontent="$(shasum -a256 ./*)" ||
        failure "Failed to generate shasums in ${directory}"

    sed 's/\.\///g' <( printf "%s" "${shacontent}" ) > "${product}_${version}_SHA256SUMS" ||
        failure "Failed to write shasums file"

    popd
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

# Check if gem version is already published to RubyGems
#
# $1: Name of RubyGem
# $2: Verision of RubyGem
function is_version_on_rubygems() {
    local name="${1}"
    local version="${2}"
    local result

    result="$(gem search --remote --exact --all "${name}")" ||
        failure "Failed to retreive remote version list from RubyGems"
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
        failure "RUBYGEMS_API_KEY is currently unset"
    fi

    local gem_config
    local result

    gem_config="$(mktemp -p ./)" || failure "Failed to create temporary credential file"
    wrap gem build ./*.gemspec \
        "Failed to build RubyGem"
    printf -- "---\n:rubygems_api_key: %s\n" "${RUBYGEMS_API_KEY}" > "${gem_config}"
    wrap_raw gem push --config-file "${gem_config}" ./*.gem
    result=$?
    rm -f "${gem_config}"

    if [ $result -ne 0 ]; then
        failure "Failed to publish RubyGem"
    fi
}

# Publish gem to the hashigems repository
#
# $1: Path to gem file to publish
function publish_to_hashigems() {
    local path="${1}"
    if [ -z "${path}" ]; then
        failure "Path to built gem required for publishing to hashigems"
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
        failure "Failed to create working directory for hashigems publish"
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
        failure "Invalidation of hashigems CDN distribution failed"
    invalid_id="$(printf '%s' "${invalid}" | jq -r ".Invalidation.Id")"
    if [ -z "${invalid_id}" ]; then
        failure "Failed to determine the ID of the hashigems CDN invalidation request"
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
        failure "Failed to determine default branch (is working directory git repository?)"
    echo -n "${s##*origin/}"
}

# Loads signing files for packaging. The return value can be eval'd
# to set expected environment variables for packet-exec to use.
function load-signing() {
    local secrets key result
    declare -A secrets=(
        ["MACOS_PACKAGE_CERT"]="./MacOS_PackageSigning.cert.gpg"
        ["MACOS_PACKAGE_KEY"]="./MacOS_PackageSigning.p12.gpg"
        ["MACOS_CODE_CERT"]="./MacOS_CodeSigning.p12.gpg"
        ["WIN_SIGNING_KEY"]="./Win_CodeSigning.p12.gpg"
    )

    for key in "${!secrets[@]}"; do
        local local_path="${secrets[${key}]}"
        local var_name="PKT_SECRET_FILE_${key}"
        local content_variable="${key}_CONTENT"

        if [ -z "${!content_variable}" ]; then
            failure "Missing content in environment variable: ${content_variable}"
        fi

        # Content will be encoded so first we decode
        local content

        printf "%s" "${!content_variable}" > ./.load-signing-temp-file
        wrap gpg --dearmor ./.load-signing-temp-file \
            "Failed to decode secret file content"
        wrap mv ./.load-signing-temp-file.gpg "${local_path}" \
            "Failed to move signing content to destination"
        rm -f ./.load-signing-temp-file*

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
            *) failure "Invalid flag provided to slack" ;;
        esac
    done
    shift $((OPTIND-1))

    # If we don't have a webhook provided, stop here
    if [ -z "${webhook}" ]; then
        (>&2 echo "ERROR: Cannot send Slack notification, webhook unset")
        return 1
    fi

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
# be located in private (though not required) HashiCorp repositories.
# It will attempt to download the correct artifact for the current
# platform based on HashiCorp naming conventions. It expects that
# the name of the repository is the name of the tool.
#
# $1: Name of repository
function install_hashicorp_tool() {
    local tool_name="${1}"
    local extensions=("zip" "tar.gz")
    local asset release_content tmp

    tmp="$(mktemp -d --tmpdir vagrantci-XXXXXX)" ||
        failure "Failed to create temporary working directory"
    pushd "${tmp}"

    if [ -z "${HASHIBOT_TOKEN}" ]; then
        failure "HASHIBOT_TOKEN is required for internal tool install"
    fi

    local platform
    platform="$(uname -s)" || failure "Failed to get local platform name"
    platform="${platform,,}" # downcase the platform name

    local arches=()

    local arch
    arch="$(uname -m)" || failure "Failed to get local platform architecture"
    arches+=("${arch}")

    # If the architecture is listed as x86_64, add amd64 to the
    # arches collection. Hashicorp naming scheme is to use amd64 in
    # the file name, but isn't always followed
    if [ "${arch}" = "x86_64" ]; then
        arches+=("amd64")
    fi

    release_content=$(curl -SsL --fail -H "Authorization: token ${HASHIBOT_TOKEN}" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/hashicorp/${tool_name}/releases/latest") ||
      failure "Failed to request latest releases for hashicorp/${tool_name}"

    local exten
    for exten in "${extensions[@]}"; do
        for arch in "${arches[@]}"; do
            local suffix="${platform}_${arch}.${exten}"
            asset=$(printf "%s" "${release_content}" | jq -r \
                '.assets[] | select(.name | contains("'"${suffix}"'")) | .url')
            if [ -n "${asset}" ]; then
               break
            fi
        done
        if [ -n "${asset}" ]; then
            break
        fi
    done

    if [ -z "${asset}" ]; then
        failure "Failed to find release of hashicorp/${tool_name} for ${platform} ${arch[0]}"
    fi

    wrap curl -SsL --fail -o "${tool_name}.${exten}" -H "Authorization: token ${HASHIBOT_TOKEN}" \
        -H "Accept: application/octet-stream" "${asset}" \
        "Failed to download latest release for hashicorp/${tool_name}"

    if [ "${exten}" = "zip" ]; then
        wrap unzip "${tool_name}.${exten}" \
            "Failed to unpack latest release for hashicorp/${tool_name}"
    else
        wrap tar xf "${tool_name}.${exten}" \
            "Failed to unpack latest release for hashicorp/${tool_name}"
    fi

    rm -f "${tool_name}.${exten}"

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
        failure "Failed to create temporary working directory"
    pushd "${tmp}"

    release_content=$(curl -SsL --fail \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${org_name}/${tool_name}/releases/latest") ||
        failure "Failed to request latest releases for ${org_name}/${tool_name}"

    asset=$(printf "%s" "${release_content}" | jq -r \
        '.assets[] | select(.name | contains("linux_amd64")) | .url') ||
        failure "Failed to detect latest release for ${org_name}/${tool_name}"

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
            failure "Failed to locate executable in package directory for ${org_name}/${tool_name}"
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
        failure "Cannot setup packet, missing token"
    fi
    if [ -z "${PACKET_EXEC_PROJECT_ID}" ]; then
        failure "Cannot setup packet, missing project"
    fi
    if [ -z "${PACKET_SSH_KEY_CONTENT}" ]; then
        failure "Cannot setup packet, missing ssh key"
    fi

    install_hashicorp_tool "packet-exec"

    # Write the ssh key to disk
    local content
    content="$(base64 --decode - <<< "${PACKET_SSH_KEY_CONTENT}")" ||
        failure "Cannot setup packet, failed to decode key"
    touch ./packet-key
    chmod 0600 ./packet-key
    printf "%s" "${content}" > ./packet-key
    local working_directory
    working_directory="$(pwd)" ||
        failure "Cannot setup packet, failed to determine working directory"
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
    local gtoken curl_args
    curl_args=()

    if [ -n "${HASHIBOT_TOKEN}" ]; then
        gtoken="${HASHIBOT_TOKEN}"
    elif [ -n "${GITHUB_TOKEN}" ]; then
        gtoken="${GITHUB_TOKEN}"
    fi

    if [ -n "${gtoken}" ]; then
        curl_args+=("-H" "Authorization: token ${gtoken}")
    fi

    local release_repo release_name asset_pattern release_content
    release_repo="${1}/${2}"
    release_name="${3}"
    asset_pattern="${4}"

    curl_args+=("-SsL" "--fail" "-H" "Content-Type: application/json")
    curl_args+=("https://api.github.com/repos/${release_repo}/releases/tags/${release_name}")

    release_content=$(curl "${curl_args[@]}") ||
        failure "Failed to request release (${release_name}) for ${release_repo}"

    local asset_list name_list asset_names query artifact asset
    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    asset_list=$(printf "%s" "${release_content}" | jq -r "${query} | .url") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    curl_args=()
    if [ -n "${gtoken}" ]; then
        curl_args+=("-H" "Authorization: token ${gtoken}")
    fi
    curl_args+=("-SsL" "--fail" "-H" "Accept: application/octet-stream")

    readarray -t assets <  <(printf "%s" "${asset_list}")
    readarray -t asset_names < <(printf "%s" "${name_list}")

    for ((idx=0; idx<"${#assets[@]}"; idx++ )); do
        asset="${assets[$idx]}"
        artifact="${asset_names[$idx]}"

        wrap curl "${curl_args[@]}" -o "${artifact}" "${asset}" \
            "Failed to download asset (${artifact}) in release ${release_name} for ${release_repo}"
    done
}

# Download artifact(s) from GitHub draft release. A draft release is not
# attached to a tag and therefore is referenced by the release name directly.
# The artifact pattern is simply a substring that is matched against the
# artifact download URL. Artifact(s) will be downloaded to the working directory.
#
# $1: organization name
# $2: repository name
# $3: release name
# $4: artifact pattern (optional, all artifacts downloaded if omitted)
function github_draft_release_assets() {
    local gtoken

    if [ -n "${HASHIBOT_TOKEN}" ]; then
        gtoken="${HASHIBOT_TOKEN}"
    elif [ -n "${GITHUB_TOKEN}" ]; then
        gtoken="${GITHUB_TOKEN}"
    else
        failure "Fetching draft release assets requires hashibot or github token with write permission"
    fi

    local release_list release_repo release_name asset_pattern release_content
    local name_list query artifact asset_names idx page

    release_repo="${1}/${2}"
    release_name="${3}"
    asset_pattern="${4}"

    page=$((1))
    while [ -z "${release_content}" ]; do
        release_list=$(curl -SsL --fail \
            -H "Authorization: token ${gtoken}" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/${release_repo}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for ${release_repo}"

        # If there's no more results, just bust out of the loop
        if [ "$(jq 'length' <( printf "%s" "${release_list}" ))" -lt "1" ]; then
            break
        fi

        query="$(printf '.[] | select(.name == "%s")' "${release_name}")"

        release_content=$(printf "%s" "${release_list}" | jq -r "${query}")

        ((page++))
    done

    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    asset_list=$(printf "%s" "${release_content}" | jq -r "${query} | .url") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    readarray -t assets <  <(printf "%s" "${asset_list}")
    readarray -t asset_names < <(printf "%s" "${name_list}")

    if [ "${#assets[@]}" -ne "${#asset_names[@]}" ]; then
        failure "Failed to match download assets with names in release list for ${release_repo}"
    fi

    for ((idx=0; idx<"${#assets[@]}"; idx++ )); do
        asset="${assets[$idx]}"
        artifact="${asset_names[$idx]}"
        wrap curl -SsL --fail -o "${artifact}" \
            -H "Authorization: token ${gtoken}" \
            -H "Accept: application/octet-stream" "${asset}" \
            "Failed to download asset in release (${release_name}) for ${release_repo} - ${artifact}"

    done
}

# This function is identical to the github_draft_release_assets
# function above with one caveat: it does not download the files.
# Each file that would be downloaded is simply touched in the
# current directory. This provides an easy way to check the
# files that would be downloaded without actually downloading
# them.
#
# An example usage of this can be seen in the vagrant package
# building where we use this to enable building missing substrates
# or packages on re-runs and only download the artifacts if
# actually needed.
function github_draft_release_asset_names() {
    local gtoken

    if [ -n "${HASHIBOT_TOKEN}" ]; then
        gtoken="${HASHIBOT_TOKEN}"
    elif [ -n "${GITHUB_TOKEN}" ]; then
        gtoken="${GITHUB_TOKEN}"
    else
        failure "Fetching draft release assets requires hashibot or github token with write permission"
    fi

    local release_list release_repo release_name asset_pattern release_content
    local name_list query artifact asset_names idx page

    release_repo="${1}/${2}"
    release_name="${3}"
    asset_pattern="${4}"

    page=$((1))
    while [ -z "${release_content}" ]; do
        release_list=$(curl -SsL --fail \
            -H "Authorization: token ${gtoken}" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/${release_repo}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for ${release_repo}"

        # If there's no more results, just bust out of the loop
        if [ "$(jq 'length' <( printf "%s" "${release_list}" ))" -lt "1" ]; then
            break
        fi


        query="$(printf '.[] | select(.name == "%s")' "${release_name}")"

        release_content=$(printf "%s" "${release_list}" | jq -r "${query}")

        ((page++))
    done

    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    readarray -t asset_names < <(printf "%s" "${name_list}")

    for ((idx=0; idx<"${#asset_names[@]}"; idx++ )); do
        artifact="${asset_names[$idx]}"
        touch "${artifact}"
    done
}

# Delete any draft releases that are older than the
# given number of days
#
# $1: days
# $2: repository (optional, defaults to current repo)
function github_draft_release_prune() {
    local gtoken

    if [ -n "${HASHIBOT_TOKEN}" ]; then
        gtoken="${HASHIBOT_TOKEN}"
    elif [ -n "${GITHUB_TOKEN}" ]; then
        gtoken="${GITHUB_TOKEN}"
    else
        failure "Fetching draft release assets requires hashibot or github token with write permission"
    fi

    local days prune_repo
    days="${1}"
    prune_repo="${2:-$repository}"

    local prune_seconds page now
    now="$(date '+%s')"
    prune_seconds=$(("${now}"-("${days}" * 86400)))

    page=$((1))
    while true; do
        local release_list list_length

        release_list=$(curl -SsL --fail \
            -H "Authorization: token ${gtoken}" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/${prune_repo}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for pruning on ${prune_repo}"

        list_length="$(jq 'length' <( printf "%s" "${release_list}" ))" ||
            failure "Failed to calculate release length for pruning on ${prune_repo}"

        if [ "${list_length}" -lt "1" ]; then
            break
        fi

        local count entry i release_draft release_name release_id release_create date_check
        count="$(jq 'length' <( printf "%s" "${release_list}" ))"
        for (( i=0; i < "${count}"; i++ )); do
            entry="$(jq ".[${i}]" <( printf "%s" "${release_list}" ))" ||
                failure "Failed to read entry for pruning on ${prune_repo}"
            release_draft="$(jq -r '.draft' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry draft for pruning on ${prune_repo}"
            release_name="$(jq -r '.name' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry name for pruning on ${prune_repo}"
            release_id="$(jq -r '.id' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry ID for pruning on ${prune_repo}"
            release_create="$(jq -r '.created_at' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry created date for pruning on ${prune_repo}"
            date_check="$(date --date="${release_create}" '+%s')" ||
                failure "Failed to parse entry created date for pruning on ${prune_repo}"

            if [ "${release_draft}" != "true" ]; then
                printf "Skipping %s because not draft release\n" "${release_name}"
                continue
            fi

            if [ "$(( "${date_check}" ))" -lt "${prune_seconds}" ]; then
                printf "Deleting draft release %s from %s\n" "${release_name}" "${prune_repo}"
                curl -SsL --fail \
                    -X DELETE \
                    -H "Authorization: token ${gtoken}" \
                    "https://api.github.com/repos/${prune_repo}/releases/${release_id}" ||
                    failure "Failed to prune draft release ${release_name} from ${prune_repo}"
            fi
        done
        ((page++))
    done
}

# Delete draft release with given name
#
# $1: name of draft release
# $2: repository (optiona, defaults to current repo)
function delete_draft_release() {
    local gtoken

    if [ -n "${HASHIBOT_TOKEN}" ]; then
        gtoken="${HASHIBOT_TOKEN}"
    elif [ -n "${GITHUB_TOKEN}" ]; then
        gtoken="${GITHUB_TOKEN}"
    else
        failure "Fetching draft release assets requires hashibot or github token with write permission"
    fi

    local draft_name="${1}"
    local delete_repo="${2:-$repository}"

    if [ -z "${draft_name}" ]; then
        failure "Draft name is required for deletion"
    fi

    if [ -z "${delete_repo}" ]; then
        failure "Repository is required for draft deletion"
    fi

    local draft_id
    local page=$((1))
    while true; do
        local release_list list_length
        release_list=$(curl -SsL --fail \
            -H "Authorization: token ${gtoken}" \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/${delete_repo}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for draft deletion on ${delete_repo}"
        list_length="$(jq 'length' <( printf "%s" "${release_list}" ))" ||
            failure "Failed to calculate release length for draft deletion on ${delete_repo}"

        # If the list is empty then the draft release does not exist
        # so we can just return success
        if [ "${list_length}" -lt "1" ]; then
            return 0
        fi

        local entry i release_draft release_id release_name
        for (( i=0; i < "${list_length}"; i++ )); do
            entry="$(jq ".[$i]" <( printf "%s" "${release_list}" ))" ||
                failure "Failed to read entry for draft deletion on ${delete_repo}"
            release_draft="$(jq -r '.draft' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry draft for draft deletion on ${delete_repo}"
            release_id="$(jq -r '.id' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry ID for draft deletion on ${delete_repo}"
            release_name="$(jq -r '.name' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry name for draft deletion on ${delete_repo}"

            # If the names don't match, skip
            if [ "${release_name}" != "${draft_name}" ]; then
                continue
            fi

            # If the release is not a draft, fail
            if [ "${release_draft}" != "true" ]; then
                failure "Cannot delete draft '${draft_name}' from '${delete_repo}' - release is not a draft"
            fi

            # If we are here, we found a match
            draft_id="${release_id}"
            break
        done

        if [ -n "${draft_id}" ]; then
            break
        fi
    done

    # If no draft id was found, the release was not found
    # so we can just return success
    if [ -z "${draft_id}" ]; then
        return 0
    fi

    # Still here? Okay! Delete the draft
    printf "Deleting draft release %s from %s\n" "${draft_name}" "${delete_repo}"
    curl -SsL --fail \
        -X DELETE \
        -H "Authorization: token ${gtoken}" \
        "https://api.github.com/repos/${delete_repo}/releases/${draft_id}" ||
        failure "Failed to prune draft release ${draft_name} from ${delete_repo}"

}

# This function is used to make requests to the GitHub API. It
# accepts the same argument list that would be provided to the
# curl executable. It will check the response status and if a
# 429 is received (rate limited) it will pause until the defined
# rate limit reset time and then try again.
#
# NOTE: Informative information (like rate limit pausing) will
# be printed to stderr. The response body will be printed to
# stdout. Return value of the function will be the exit code
# from the curl process.
function github_request() {
    local request_exit=0
    local raw_response_content

    # Make our request
    raw_response_content="$(curl -i -SsL --fail "${@#}")" || request_exit="${?}"

    local status
    local ratelimit_reset
    local response_content=""

    # Read the response into lines for processing
    local lines
    mapfile -t lines < <( printf "%s" "${raw_response_content}" )

    # Process the lines to extract out status and rate
    # limit information. Populate the response_content
    # variable with the actual response value
    local i
    for (( i=0; i < "${#lines[@]}"; i++ )); do
        # The line will have a trailing `\r` so just
        # trim it off
        local line="${lines[$i]%%$'\r'*}"

        if [ -z "${line}" ] && [[ "${status}" = "2"* ]]; then
            local start="$(( i + 1 ))"
            local remain="$(( "${#lines[@]}" - "${start}" ))"
            local response_lines=("${lines[@]:$start:$remain}")
            response_content="${response_lines[*]}"
            break
        fi

        if [[ "${line}" == "HTTP/"* ]]; then
            status="${line##* }"
        fi
        if [[ "${line}" == "x-ratelimit-reset"* ]]; then
            ratelimit_reset="${line##*ratelimit-reset: }"
        fi
    done

    # If the status was not detected, force an error
    if [ -z "${status}" ]; then
        failure "Failed to detect response status for GitHub request"
    fi

    # If the status was a 2xx code then everything is good
    # and we can return the response and be done
    if [[ "${status}" = "2"* ]]; then
        printf "%s" "${response_content}"
        return 0
    fi

    # If we are being rate limited, print a notice and then
    # wait until the rate limit will be reset
    if [[ "${status}" = "429" ]]; then
        # If the ratelimit reset was not detected force an error
        if [ -z "${ratelimit_reset}" ]; then
            failure "Failed to detect rate limit reset time for GitHub request"
        fi

        local reset_date
        reset_date="$(date --date="@${ratelimit_reset}")" ||
            failure "Failed to GitHub parse ratelimit reset timestamp (${ratelimit_reset})"

        local now
        now="$( date '+%s' )" || failure "Failed to get current timestamp in ratelimit check"
        local reset_wait="$(( "${ratelimit_reset}" - "${now}" + 2))"

        printf "GitHub rate limit encountered, reset at %s (waiting %d seconds)\n" \
            "${reset_date}" "${reset_wait}" >&2

        sleep "${reset_wait}" || failure "Pause for GitHub rate limited request retry failed"

        github_request "${@}"
        return "${?}"
    fi

    # At this point we just need to return error information
    printf "GitHub request returned HTTP status: %d\n" "${status}" >&2
    printf "Response body: %s\n" "${response_content}" >&2

    return "${request_exit}"
}

# Lock issues which have been closed for longer than
# provided number of days. A date can optionally be
# provided which will be used as the earliest date to
# search. A message can optionally be provided which
# will be added as a comment in the issue before locking.
#
# -d: number of days
# -m: message to include when locking the issue (optional)
# -s: date to begin searching from (optional)
function lock_issues() {
    local OPTIND opt days start since message
    while getopts ":d:s:m:" opt; do
        case "${opt}" in
            "d") days="${OPTARG}" ;;
            "s") start="${OPTARG}" ;;
            "m") message="${OPTARG}" ;;
            *) failure "Invalid flag provided to lock_issues" ;;
        esac
    done
    shift $((OPTIND-1))

    # If days where not provided, return error
    if [ -z "${days}" ]; then
        failure "Number of days since closed required for locking issues"
    fi
    # If a start date was provided, check that it is a format we can read
    if [ -n "${start}" ]; then
        if ! since="$(date --iso-8601=seconds --date="${start}" 2> /dev/null)"; then
            failure "$(printf "Start date provided for issue locking could not be parsed (%s)" "${start}")"
        fi
    fi
    # GITHUB_TOKEN must be set for locking
    if [ -z "${GITHUB_TOKEN}" ]; then
        failure "GITHUB_TOKEN is required for locking issues"
    fi

    local req_args=()
    # Start with basic setup
    req_args+=("-H" "Accept: application/vnd.github+json")
    # Add authorization header
    req_args+=("-H" "Authorization: token ${GITHUB_TOKEN}")
    # Construct our request endpoint
    local req_endpoint="https://api.github.com/repos/${repository}/issues"
    # Page counter for requests
    local page=$(( 1 ))
    # Request arguments
    local req_params=("per_page=20" "state=closed")

    # If we have a start time, include it
    if [ -n "${since}" ]; then
        req_params+=("since=${since}")
    fi

    # Compute upper bound for issues we can close
    local lock_seconds now
    now="$(date '+%s')"
    lock_seconds=$(("${now}"-("${days}" * 86400)))

    while true; do
        # Join all request parameters with '&'
        local IFS_BAK="${IFS}"
        IFS="&"
        local all_params=("${req_params[*]}" "page=${page}")
        local params="${all_params[*]}"
        IFS="${IFS_BAK}"

        local issue_list issue_count
        # Make our request to get a page of issues
        issue_list="$(github_request "${req_args[@]}" "${req_endpoint}?${params}")" ||
            failure "Failed to get repository issue list for ${repository}"
        issue_count="$(jq 'length' <( printf "%s" "${issue_list}" ))" ||
            failure "Failed to compute count of issues in list for ${repository}"

        if [ -z "${issue_count}" ] || [ "${issue_count}" -lt 1 ]; then
            break
        fi

        # Iterate through the list
        local i
        for (( i=0; i < "${issue_count}"; i++ )); do
            # Extract the issue we are going to process
            local issue
            issue="$(jq ".[${i}]" <( printf "%s" "${issue_list}" ))" ||
                failure "Failed to extract issue from list for ${repository}"

            # Grab the ID of this issue
            local issue_id
            issue_id="$(jq -r '.id' <( printf "%s" "${issue}" ))" ||
                failure "Failed to read ID of issue for ${repository}"

            # First check if issue is already locked
            local issue_locked
            issue_locked="$(jq -r '.locked' <( printf "%s" "${issue}" ))" ||
                failure "Failed to read locked state of issue for ${repository}"

            if [ "${issue_locked}" == "true" ]; then
                printf "Skipping %s#%s because it is already locked\n" "${repository}" "${issue_id}"
                continue
            fi

            # Get the closed date
            local issue_closed
            issue_closed="$(jq -r '.closed_at' <( printf "%s" "${issue}" ))" ||
                failure "Failed to read closed at date of issue for ${repository}"

            # Convert closed date to unix timestamp
            local date_check
            date_check="$( date --date="${issue_closed}" '+%s' )" ||
                failure "Failed to parse closed at date of issue for ${repository}"

            # Check if the issue is old enough to be locked
            if [ "$(( "${date_check}" ))" -lt "${lock_seconds}" ]; then
                printf "Locking issue %s#%s\n" "${repository}" "${issue_id}"

                # If we have a comment to add before locking, do that now
                if [ -n "${message}" ]; then
                    local message_json
                    message_json=$(jq -n \
                        --arg msg "$(printf "%b" "${message}")" \
                        '{body: $msg}'
                        ) || failure "Failed to create issue comment JSON content for ${repository}"

                    github_request "${req_args[@]}" -X POST "${req_endpoint}/${issue_id}/comments" -d "${message_json}" ||
                        failure "Failed to create issue comment on ${repository}#${issue_id}"
                fi

                # Lock the issue
                github_request "${req_args[@]}" -X PUT "${req_endpoint}/${issue_id}/lock" -d '{"lock_reason":"resolved"}' ||
                    failure "Failed to lock issue ${repository}#${issue_id}"
            fi
        done

        ((page++))
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
        failure "Repository dispatch requires hashibot configuration"
    fi

    local arg payload_key payload_value jqargs payload \
        msg_template msg dorg_name drepo_name event_type

    dorg_name="${1}"
    drepo_name="${2}"
    event_type="${3}"

    # shellcheck disable=SC2016
    payload_template='{"vagrant-ci": $vagrant_ci'
    jqargs=("--arg" "vagrant_ci" "true")
    for arg in "${@:4}"; do
        payload_key="${arg%%=*}"
        payload_value="${arg##*=}"
        payload_template+=", \"${payload_key}\": \$${payload_key}"
        # shellcheck disable=SC2089
        jqargs+=("--arg" "${payload_key}" "${payload_value}")
    done
    payload_template+="}"

    # NOTE: we want the arguments to be expanded below
    payload=$(jq -n "${jqargs[@]}" "${payload_template}" ) ||
        failure "Failed to generate repository dispatch payload"

    # shellcheck disable=SC2016
    msg_template='{event_type: $event_type, client_payload: $payload}'
    msg=$(jq -n \
        --argjson payload "${payload}" \
        --arg event_type "${event_type}" \
        "${msg_template}" \
        ) || failure "Failed to generate repository dispatch message"

    wrap curl -SsL --fail -X POST "https://api.github.com/repos/${dorg_name}/${drepo_name}/dispatches" \
        -H 'Accept: application/vnd.github.everest-v3+json' \
        -u "${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}" \
        --data "${msg}" \
        "Repository dispatch to ${dorg_name}/${drepo_name} failed"
}

# Copy a function to a new name
#
# $1: Original function name
# $2: Copy function name
function copy_function() {
    local orig="${1}"
    local new="${2}"
    local fn
    fn="$(declare -f "${orig}")" ||
        failure "Orignal function (${orig}) not defined"
    fn="${new}${fn#*"${orig}"}"
    eval "${fn}"
}

# Rename a function to a new name
#
# $1: Original function name
# $2: New function name
function rename_function() {
    local orig="${1}"
    copy_function "${@}"
    unset -f "${orig}"
}

# Cleanup wrapper so we get some output that cleanup is starting
function _cleanup() {
    (>&2 echo "* Running cleanup task...")
    cleanup
}

# Stub cleanup method which can be redefined
# within actual script
function cleanup() {
    (>&2 echo "** No cleanup tasks defined")
}

# Only setup our cleanup trap and fail alias when not in testing
if [ -z "${BATS_TEST_FILENAME}" ]; then
    trap _cleanup EXIT
    # This is a compatibility alias for existing scripts which
    # use the common.sh library. BATS support defines a `fail`
    # function so it has been renamed `failure` to prevent the
    # name collision. When not running under BATS we enable the
    # `fail` function so any scripts that have not been updated
    # will not be affected.
    copy_function "failure" "fail"
fi

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
[ "${BASH_VERSINFO:-0}" -ge "4" ] || failure "Expected bash version >= 4 (is: ${BASH_VERSINFO:-0})"

# Enable debugging. This needs to be enabled with
# extreme caution when used on public repositories.
# Output with debugging enabled will likely include
# secret values which should not be publicly exposed.
#
# If repository is public, FORCE_PUBLIC_DEBUG environment
# variable must also be set.

priv_args=("-H" "Accept: application/json")
# If we have a token available, use it for the check query
if [ -n "${HASHIBOT_TOKEN}" ]; then
    priv_args+=("-H" "Authorization: token ${GITHUB_TOKEN}")
elif [ -n "${GITHUB_TOKEN}" ]; then
    priv_args+=("-H" "Authorization: token ${HASHIBOT_TOKEN}")
fi

priv_check="$(curl "${priv_args[@]}" -s "https://api.github.com/repos/${GITHUB_REPOSITORY}" | jq .private)" ||
    failure "Repository visibility check failed"

# If the value wasn't true we unset it to indicate not private. The
# repository might actually be private but we weren't supplied a
# token (or one with correct permissions) so we fallback to the safe
# assumption of not private.
if [ "${priv_check}" != "true" ]; then
    readonly is_public="1"
    readonly is_private=""
else
    readonly is_public=""
    # shellcheck disable=SC2034
    readonly is_private="1"
fi

# If we have debugging enabled, check if we are in a private
# repository. If we are, enable it. If we are not, check if
# debugging is being forced and allow it. Otherwise, return
# an error message to prevent leaking unintended information.
if [ "${DEBUG}" != "" ]; then
    if [ -n "${is_public}" ]; then
        if [ "${FORCE_PUBLIC_DEBUG}" != "" ]; then
            set -x
            output="/dev/stdout"
        else
            failure "Cannot enable debug mode on public repository unless forced"
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
    # shellcheck disable=SC2034
    readonly release
fi

# Seed an initial output file
output_file > /dev/null 2>&1
