#!/usr/bin/env bash
# shellcheck disable=SC2119
# shellcheck disable=SC2164

# If the bash version isn't at least 4, bail
if [ "${BASH_VERSINFO:-0}" -lt "4" ]; then
    printf "ERROR: Expected bash version >= 4 (is: %d)" "${BASH_VERSINFO:-0}"
    exit 1
fi

# Lets have some emojis
WARNING_ICON="⚠️"
ERROR_ICON="🛑"

# Coloring
# shellcheck disable=SC2034
TEXT_BOLD='\e[1m'
TEXT_RED='\e[31m'
# shellcheck disable=SC2034
TEXT_GREEN='\e[32m'
TEXT_YELLOW='\e[33m'
TEXT_CYAN='\e[36m'
TEXT_CLEAR='\e[0m'

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
# This value is used in our cleanup trap to restore the value in cases
# where a function call may have failed and did not restore it
readonly _repository_backup="${repository}"

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

# If we are on a runner and debug mode is enabled,
# enable debug mode for ourselves too
if [ -n "${RUNNER_DEBUG}" ]; then
    DEBUG=1
fi

# If DEBUG is enabled and we are running tests,
# flag it so we can adjust where output is sent.
if [ -n "${DEBUG}" ] && [ -n "${BATS_TEST_FILENAME}" ]; then
    DEBUG_WITH_BATS=1
fi

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
function aws_deprected() {
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
        (>&2 echo "AWS assume role error: ${aws_output}")
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

# Write debug output to stderr. Message template
# and arguments are passed to `printf` for formatting.
#
# -f FN_NAME - set function name in output
# -s SCRIPT_NAME - set script name in ouput
#
# $1: message template
# $#: message arguments
#
# NOTE: Debug output is only displayed when DEBUG is set
function debug() {
    if [ -n "${DEBUG}" ]; then
        local msg_template="${1}"
        local i=$(( ${#} - 1 ))
        local msg_args=("${@:2:$i}")
        # Update template to include caller information
        msg_template=$(printf "<%s(%s:%d)> %s" "${FUNCNAME[1]}" "${BASH_SOURCE[1]}" "${BASH_LINENO[0]}" "${msg_template}")
        #shellcheck disable=SC2059
        msg="$(printf "${msg_template}" "${msg_args[@]}")"

        if [ -n "${DEBUG_WITH_BATS}" ]; then
            printf "%b%s%b\n" "${TEXT_CYAN}" "${msg}" "${TEXT_CLEAR}" >&3
        else
            printf "%b%s%b\n" "${TEXT_CYAN}" "${msg}" "${TEXT_CLEAR}" >&2
        fi
    fi
}

# Write failure message, send error to configured
# slack, and exit with non-zero status. If an
# "$(output_file)" file exists, the last 5 lines will be
# included in the slack message.
#
# $1: Failure message
function failure() {
    local msg_template="${1}"
    local i=$(( ${#} - 1 ))
    local msg_args=("${@:2:$i}")

    #shellcheck disable=SC2059
    msg="$(printf "${msg_template}" "${msg_args[@]}")"

    printf "%s %b%s%b\n" "${ERROR_ICON}" "${TEXT_RED}" "${msg}" "${TEXT_CLEAR}" >&2

    if [ -n "${SLACK_WEBHOOK}" ]; then
        if [ -f "$(output_file)" ]; then
            slack -s error -m "ERROR: ${1}" -f "$(output_file)" -T 5
        else
            slack -s error -m "ERROR: ${1}"
        fi
    fi
    exit 1
}

# Write warning message, send warning to configured
# slack
#
# $1: Warning message
function warn() {
    local msg_template="${1}"
    local i=$(( ${#} - 1 ))
    local msg_args=("${@:2:$i}")

    #shellcheck disable=SC2059
    msg="$(printf "${msg_template}" "${msg_args[@]}")"

    printf "%s %b%s%b\n" "${WARNING_ICON}" "${TEXT_YELLOW}" "${msg}" "${TEXT_CLEAR}" >&2

    if [ -n "${SLACK_WEBHOOK}" ]; then
        if [ -f "$(output_file)" ]; then
            slack -s warn -m "WARNING: ${1}" -f "$(output_file)"
        else
            slack -s warn -m "WARNING: ${1}"
        fi
    fi
}

# Write an informational message
function info() {
    local msg_template="${1}\n"
    local i=$(( ${#} - 1 ))
    local msg_args=("${@:2:$i}")

    #shellcheck disable=SC2059
    printf "${msg_template}" "${msg_args[@]}" >&2
}

# Execute command while redirecting all output to
# a file (file is used within fail mesage on when
# command is unsuccessful). Final argument is the
# error message used when the command fails.
#
# $@{1:$#-1}: Command to execute
# $@{$#}: Failure message
function wrap() {
    local i=$((${#} - 1))
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
    i=$((${#} - 1))
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
    debug "executing 'pushd %s'" "${*}"
    wrap command builtin pushd "${@}" \
        "pushd command failed"
}

# Wrap the popd command so we fail
# if the popd command fails. Arguments
# are just passed through.
# shellcheck disable=SC2120
function popd() {
    debug "executing 'popd %s'" "${*}"
    wrap command builtin popd "${@}" \
        "popd command failed"
}

# Get the full path directory for a given
# file path. File is not required to exist.
# NOTE: Parent directories of given path will
#       be created.
#
# $1: file path
function file_directory() {
    local path="${1?File path is required}"
    local dir
    if [[ "${path}" != *"/"* ]]; then
        dir="."
    else
        dir="${path%/*}"
    fi
    if [ ! -d "${dir}" ]; then
        mkdir -p "${dir}" ||
            failure "Could not create directory (%s)" "${dir}"
    fi
    pushd "${dir}"
    dir="$(pwd)" ||
        failure "Could not read directory path (%s)" "${dir}"
    popd
    printf "%s" "${dir}"
}

# Wait until the number of background jobs falls below
# the maximum number provided. If the max number was reached
# and waiting was performed until a process completed, the
# string "waited" will be printed to stdout.
#
# NOTE: using `wait -n` would be cleaner but only became
#       available in bash as of 4.3
#
# $1: maximum number of jobs
function background_jobs_limit() {
    local max="${1}"
    if [ -z "${max}" ] || [[ "${max}" = *[!0123456789]* ]]; then
        failure "Maximum number of background jobs required"
    fi

    local debug_printed
    local jobs
    mapfile -t jobs <<< "$(jobs -p)" ||
        failure "Could not read background job list"
    while [ "${#jobs[@]}" -ge "${max}" ]; do
        if [ -z "${debug_printed}" ]; then
            debug "max background jobs reached (%d), waiting for free process" "${max}"
            debug_printed="1"
        fi
        sleep 1
        jobs=()
        local j_pids
        mapfile -t j_pids <<< "$(jobs -p)" ||
            failure "Could not read background job list"
        for j in "${j_pids[@]}"; do
            if kill -0 "${j}" > /dev/null 2>&1; then
                jobs+=( "${j}" )
            fi
        done
    done
    if [ -n "${debug_printed}" ]; then
        debug "background jobs count (%s) under max, continuing" "${#jobs[@]}"
        printf "waited"
    fi
}

# Reap a completed background process. If the process is
# not complete, the process is ignored. The success/failure
# returned from this function only applies to the process
# identified by the provided PID _if_ the matching PID value
# was written to stdout
#
# $1: PID
function reap_completed_background_job() {
    local pid="${1}"
    if [ -z "${pid}" ]; then
        failure "PID of process to reap is required"
    fi
    if kill -0 "${pid}" > /dev/null 2>&1; then
        debug "requested pid to reap (%d) has not completed, ignoring" "${pid}"
        return 0
    fi
    # The pid can be reaped so output the pid to indicate
    # any error is from the job
    printf "%s" "${pid}"
    if ! wait "${pid}"; then
        local code="${?}"
        debug "wait error code %d returned for pid %d" "${code}" "${pid}"
        return "${code}"
    fi

    return 0
}

# Submit given file to Apple's notarization service and
# staple the notarization ticket.
#
# -i UUID: app store connect issuer ID (optional)
# -j PATH: JSON file containing API key
# -k ID:   app store connect API key ID (optional)
# -m SECS: maximum number of seconds to wait (optional, defaults to 600)
# -o PATH: path to write notarized file (optional, will modify input by default)
#
# $1: file to notarize
function notarize_file() {
    local creds_api_key_id
    local creds_api_key_path
    local creds_issuer_id
    local output_file
    local max_wait="600"

    local opt
    while getopts ":i:j:k:m:o:" opt; do
        case "${opt}" in
            "i") creds_api_key_id="${OPTARG}" ;;
            "j") creds_api_key_path="${OPTARG}" ;;
            "k") creds_issuer_id="${OPTARG}" ;;
            "m") max_wait="${OPTARG}" ;;
            "o") output_file="${OPTARG}" ;;
            *) failure "Invalid flag provided" ;;
        esac
    done
    shift $((OPTIND-1))

    # Validate credentials were provided
    if [ -z "${creds_api_key_path}" ]; then
        failure "App store connect key path required for notarization"
    fi
    if [ ! -f "${creds_api_key_path}" ]; then
        failure "Invalid path provided for app store connect key path (%s)" "${creds_api_key_path}"
    fi

    # Collect auth related arguments
    local base_args=( "--api-key-path" "${creds_api_key_path}" )
    if [ -n "${creds_api_key_id}" ]; then
        base_args+=( "--api-key" "${creds_api_key_id}" )
    fi
    if [ -n "${creds_issuer_id}" ]; then
        base_args+=( "--api-issuer" "${creds_issuer_id}" )
    fi

    local input_file="${1}"

    # Validate the input file
    if [ -z "${input_file}" ]; then
        failure "Input file is required for signing"
    fi
    if [ ! -f "${input_file}" ]; then
        failure "Cannot find input file (%s)" "${input_file}"
    fi

    # Check that rcodesign is available, and install
    # it if it is not
    if ! command -v rcodesign > /dev/null; then
        debug "rcodesign executable not found, installing..."
        install_github_tool "indygreg" "apple-platform-rs" "rcodesign"
    fi
    
    local notarize_file
    # If an output file path was defined, copy file
    # to output location before notarizing
    if [ -n "${output_file}" ]; then
        file_directory "${output_file}"
        # Remove file if it already exists
        rm -f "${output_file}" ||
            failure "Could not modify output file (%s)" "${output_file}"
        cp -f "${input_file}" "${output_file}" ||
            failure "Could not write to output file (%s)" "${output_file}"
        notarize_file="${output_file}"
        debug "notarizing file '%s' and writing to '%s'" "${input_file}" "${output_file}"
    else
        notarize_file="${input_file}"
        debug "notarizing file in place '%s'" "${input_file}"
    fi

    # Notarize the file
    local notarize_output
    if notarize_output="$(rcodesign \
        notary-submit \
        "${base_args[@]}" \
        --max-wait-seconds "${max_wait}" \
        --staple \
        "${notarize_file}" 2>&1)"; then
        return 0
    fi

    debug "notarization output: %s" "${notarize_output}"

    # Still here means notarization failure. Pull
    # the logs from the service before failing
    local submission_id="${notarize_output##*submission ID: }"
    submission_id="${submission_id%%$'\n'*}"
    rcodesign \
        notary-log \
        "${base_args[@]}" \
        "${submission_id}"

    failure "Failed to notarize file (%s)" "${input_file}"
}

# Sign a file using signore. Will automatically apply
# modified retry settings when larger files are submitted.
#
# -b NAME: binary identifier (macOS only)
# -e PATH: path to entitlements file (macOS only)
# -o PATH: path to write signed file (optional, will overwrite input by default)
# $1: file to sign
#
# NOTE: If signore is not installed, a HASHIBOT_TOKEN is
#       required for downloading the signore release. The
#       token can also be set in SIGNORE_GITHUB_TOKEN if
#       the HASHIBOT_TOKEN is already set
#
# NOTE: SIGNORE_CLIENT_ID, SIGNORE_CLIENT_SECRET, and SIGNORE_SIGNER
#       environment variables must be set prior to calling this function
function sign_file() {
    # Set 50M to be a largish file
    local largish_file_size="52428800"

    # Signore environment variables are required. Check
    # that they are set.
    if [ -z "${SIGNORE_CLIENT_ID}" ]; then
        failure "Cannot sign file, SIGNORE_CLIENT_ID is not set"
    fi
    if [ -z "${SIGNORE_CLIENT_SECRET}" ]; then
        failure "Cannot sign file, SIGNORE_CLIENT_SECRET is not set"
    fi
    if [ -z "${SIGNORE_SIGNER}" ]; then
        failure "Cannot sign file, SIGNORE_SIGNER is not set"
    fi

    local binary_identifier=""
    local entitlements=""
    local input_file="${1}"
    local output_file=""

    local opt
    while getopts ":b:e:o:" opt; do
        case "${opt}" in
            "b") binary_identifier="${OPTARG}" ;;
            "e") entitlements="${OPTARG}" ;;
            "o") output_file="${OPTARG}" ;;
            *) failure "Invalid flag provided" ;;
        esac
        shift $((OPTIND-1))
    done

    # Check that a good input file was given
    if [ -z "${input_file}" ]; then
        failure "Input file is required for signing"
    fi
    if [ ! -f "${input_file}" ]; then
        failure "Cannot find input file (%s)" "${input_file}"
    fi

    # If the output file is not set it's a replacement
    if [ -z "${output_file}" ]; then
        debug "output file is unset, will replace input file (%s)" "${input_file}"
        output_file="${input_file}"
    fi

    # This will ensure parent directories exist
    file_directory "${output_file}" > /dev/null

    # If signore command is not installed, install it
    if ! command -v "signore" > /dev/null; then
        local hashibot_token_backup="${HASHIBOT_TOKEN}"
        # If the signore github token is set, apply it
        if [ -n "${SIGNORE_GITHUB_TOKEN}" ]; then
            HASHIBOT_TOKEN="${SIGNORE_GITHUB_TOKEN}"
        fi

        install_hashicorp_tool "signore"

        # Restore the hashibot token if it was modified
        HASHIBOT_TOKEN="${hashibot_token_backup}"
    fi

    # Define base set of arguments
    local signore_args=( "sign" "--file" "${input_file}" "--out" "${output_file}" "--match-file-mode" )

    # Check the size of the file to be signed. If it's relatively
    # large, push up the max retries and lengthen the retry interval
    # NOTE: Only checked if `wc` is available
    local file_size="0"
    if command -v wc > /dev/null; then
        file_size="$(wc -c <"${input_file}")" ||
            failure "Could not determine input file size"
    fi

    if [ "${file_size}" -gt "${largish_file_size}" ]; then
        debug "largish file detected, adjusting retry settings"
        signore_args+=( "--max-retries" "30" "--retry-interval" "10s" )
    fi

    # If a binary identifier was provided then it's a macos signing
    if [ -n "${binary_identifier}" ]; then
        # shellcheck disable=SC2016
        template='{type: "macos", input_format: "EXECUTABLE", binary_identifier: $identifier}'
        payload="$(jq -n --arg identifier "${binary_identifier}" "${template}")" ||
            failure "Could not create signore payload for macOS signing"
        signore_args+=( "--signer-options" "${payload}" )
    fi

    # If an entitlement was provided, validate the path
    # and add it to the args
    if [ -n "${entitlements}" ]; then
        if [ ! -f "${entitlements}" ]; then
            failure "Invalid path for entitlements provided (%s)" "${entitlements}"
        fi
        signore_args+=( "--entitlements" "${entitlements}" )
    fi

    debug "signing file '%s' with arguments - %s" "${input_file}" "${signore_args[*]}"

    signore "${signore_args[@]}" ||
        failure "Failed to sign file '%s'" "${input_file}"

    info "successfully signed file (%s)" "${input_file}"
}

# Create a GPG signature. This uses signore to generate a
# gpg signature for a given file. If the destination
# path for the signature is not provided, it will
# be stored at the origin path with a .sig suffix
#
# $1: Path to origin file
# $2: Path to store signature (optional)
function gpg_sign_file() {
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
        debug "destination automatically set (%s)" "${destination}"
    fi

    if ! command -v signore; then
        debug "installing signore tool"
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

    if [ -z "${body}" ]; then
        body="$(release_details "${tag_name}")"
    fi

    response="$(github_create_release -o "${repo_owner}" -r "${repo_name}" -t "${tag_name}" -n "${tag_name}" -b "${body}")" ||
        failure "Failed to create GitHub release"
    local release_id
    release_id="$(printf "%s" "${response}" | jq -r '.id')" ||
        failure "Failed to extract release ID from response for %s on %s" "${tag_name}" "${repository}"

    github_upload_release_artifacts "${repo_name}" "${release_id}" "${assets}"
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

    response="$(github_create_release -o "${repo_owner}" -r "${repo_name}" -t "${ptag}" -n "${ptag}" -b "${body}" -p -m)" ||
        failure "Failed to create GitHub prerelease"
    local release_id
    release_id="$(printf "%s" "${response}" | jq -r '.id')" ||
        failure "Failed to extract prerelease ID from response for %s on %s" "${tag_name}" "${repository}"

    github_upload_release_artifacts "${repo_name}" "${release_id}" "${assets}"

    printf "New prerelease published to %s @ %s\n" "${repo_name}" "${ptag}" >&2

    printf "%s" "${ptag}"
}

# Generate a GitHub draft release
#
# $1: GitHub release name
# $2: Asset file or directory of assets
function draft_release() {
    local ptag="${1}"
    local assets="${2}"

    response="$(github_create_release -o "${repo_owner}" -r "${repo_name}" -t "${ptag}" -n "${ptag}" -b "${body}" -d)" ||
        failure "Failed to create GitHub draft release"
    local release_id
    release_id="$(printf "%s" "${response}" | jq -r '.id')" ||
        failure "Failed to extract draft release ID from response for %s on %s" "${tag_name}" "${repository}"

    github_upload_release_artifacts "${repo_name}" "${release_id}" "${assets}"

    printf "%s" "${ptag}"
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
    printf "CHANGELOG:\n\nhttps://github.com/%s/blob/%s/CHANGELOG.md" "${repository}" "${tag_name}"
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
    debug "checking asset directory was provided"
    if [ -z "${directory}" ]; then
        failure "No asset directory was provided for HashiCorp release"
    fi
    debug "checking that asset directory exists"
    if [ ! -d "${directory}" ]; then
        failure "Asset directory for HashiCorp release does not exist (${directory})"
    fi

    # SHASUMS checks
    debug "checking for shasums file"
    sums=("${directory}/"*SHA256SUMS)
    if [ ${#sums[@]} -lt 1 ]; then
        failure "Asset directory is missing SHASUMS file"
    fi
    debug "checking for shasums signature file"
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
    debug "validating shasums are correct"
    wrap shasum -a 256 -c ./*_SHA256SUMS \
        "Checksum validation of release assets failed"
    # Next check that the signature is valid
    gpghome=$(mktemp -qd)
    export GNUPGHOME="${gpghome}"
    debug "verifying shasums signature file using key: %s" "${HASHICORP_PUBLIC_GPG_KEY_ID}"
    wrap gpg --keyserver keyserver.ubuntu.com --recv "${HASHICORP_PUBLIC_GPG_KEY_ID}" \
        "Failed to import HashiCorp public GPG key"
    wrap gpg --verify ./*SHA256SUMS.sig ./*SHA256SUMS \
        "Validation of SHA256SUMS signature failed"
    rm -rf "${gpghome}"
    popd
}

# Generate releases-api metadata
#
# $1: Product Version
# $2: Asset directory
function hashicorp_release_generate_release_metadata() {
    local version="${1}"
    local directory="${2}"

    if ! command -v bob; then
        debug "bob executable not found, installing"
        install_hashicorp_tool "bob"
    fi

    local hc_releases_input_metadata="input-meta.json"
    # The '-metadata-file' flag expects valid json. Contents are not used for Vagrant.
    echo "{}" > "${hc_releases_input_metadata}"

    debug "generating release metadata information"
    wrap_stream bob generate-release-metadata \
        -metadata-file "${hc_releases_input_metadata}" \
        -in-dir "${directory}" \
        -version "${version}" \
        -out-file "${hc_releases_metadata_filename}" \
        "Failed to generate release metadata"

    rm -f "${hc_releases_input_metadata}"
}

# Upload release metadata and assets to the staging api
#
# $1: Product Name (e.g. "vagrant")
# $2: Product Version
# $3: Asset directory
function hashicorp_release_upload_to_staging() {
    local product="${1}"
    local version="${2}"
    local directory="${3}"

    if ! command -v "hc-releases"; then
        debug "releases-api executable not found, installing"
        install_hashicorp_tool "releases-api"
    fi

    if [ -z "${HC_RELEASES_STAGING_HOST}" ]; then
        failure "Missing required environment variable HC_RELEASES_STAGING_HOST"
    fi
    if [ -z "${HC_RELEASES_STAGING_KEY}" ]; then
       failure "Missing required environment variable HC_RELEASES_STAGING_KEY"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_STAGING_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_STAGING_KEY}"

    pushd "${directory}"

    # Create -file parameter list for hc-releases upload
    local fileParams=()
    for file in *; do
        fileParams+=("-file=${file}")
    done

    debug "uploading release assets to staging"
    wrap_stream hc-releases upload \
        -product "${product}" \
        -version "${version}" \
        "${fileParams[@]}" \
        "Failed to upload HashiCorp release assets"

    popd

    debug "creating release metadata"

    wrap_stream hc-releases metadata create \
        -product "${product}" \
        -input "${hc_releases_metadata_filename}" \
        "Failed to create metadata for HashiCorp release"

    unset HC_RELEASES_HOST
    unset HC_RELEASES_KEY
}

# Promote release from staging to production
#
# $1: Product Name (e.g. "vagrant")
# $2: Product Version
function hashicorp_release_promote_to_production() {
    local product="${1}"
    local version="${2}"

    if ! command -v "hc-releases"; then
        debug "releases-api executable not found, installing"
        install_hashicorp_tool "releases-api"
    fi

    if [ -z "${HC_RELEASES_PROD_HOST}" ]; then
        failure "Missing required environment variable HC_RELEASES_PROD_HOST"
    fi
    if [ -z "${HC_RELEASES_PROD_KEY}" ]; then
       failure "Missing required environment variable HC_RELEASES_PROD_KEY"
    fi
    if [ -z "${HC_RELEASES_STAGING_KEY}" ]; then
       failure "Missing required environment variable HC_RELEASES_STAGING_KEY"
    fi

    export HC_RELEASES_HOST="${HC_RELEASES_PROD_HOST}"
    export HC_RELEASES_KEY="${HC_RELEASES_PROD_KEY}"
    export HC_RELEASES_SOURCE_ENV_KEY="${HC_RELEASES_STAGING_KEY}"

    debug "promoting release to production"
    wrap_stream hc-releases promote \
        -product "${product}" \
        -version "${version}" \
        -source-env staging \
        "Failed to promote HashiCorp release to Production"

    unset HC_RELEASES_HOST
    unset HC_RELEASES_KEY
    unset HC_RELEASES_SOURCE_ENV_KEY
}

# Send the post-publish sns message
#
# $1: Product name (e.g. "vagrant") defaults to $repo_name
# $2: AWS Region of SNS (defaults to us-east-1)
function hashicorp_release_sns_publish() {
    local message
    local product="${1}"
    local region="${2}"

    if [ -z "${RELEASE_AWS_ACCESS_KEY_ID}" ]; then
        failure "Missing AWS access key ID for release packages SNS publish"
    fi

    if [ -z "${RELEASE_AWS_SECRET_ACCESS_KEY}" ]; then
        failure "Missing AWS access key for release packages SNS publish"
    fi

    if [ -z "${RELEASE_AWS_ASSUME_ROLE_ARN}" ]; then
        failure "Missing AWS role ARN for release packages SNS publish"
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
    debug "sending release notification to package repository"
    message=$(jq --null-input --arg product "$product" '{"product": $product}')
    wrap_stream aws sns publish --region "${region}" --topic-arn "${HC_RELEASES_PROD_SNS_TOPIC}" --message "${message}" \
        "Failed to send SNS message for package repository update"

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

    if curl --silent --fail --head "https://releases.hashicorp.com/${product}/${version}" ; then
        debug "hashicorp release of %s@%s found" "${product}" "${version}"
        return 0
    fi
    debug "hashicorp release of %s@%s not found" "${product}" "${version}"
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
    debug "generating shasums file for %s@%s" "${product}" "${version}"
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

    debug "creating hashicorp release - product: %s version: %s assets: %s" "${product}" "${version}" "${directory}"

    if ! hashicorp_release_exists "${product}" "${version}"; then
        # Jump into our artifact directory
        pushd "${directory}"

        # If any sig files happen to have been included in here,
        # just remove them as they won't be using the correct
        # signing key
        rm -f ./*.sig

        # Generate our shasums file
        debug "generating shasums file for %s@%s" "${product}" "${version}"
        generate_shasums ./ "${product}" "${version}"

        # Grab the shasums file and sign it
        local shasum_files=(./*SHA256SUMS)
        local shasum_file="${shasum_files[0]}"
        # Remove relative prefix if found
        shasum_file="${shasum_file##*/}"
        debug "signing shasums file for %s@%s" "${product}" "${version}"
        gpg_sign_file "${shasum_file[0]}"

        # Jump back out of our artifact directory
        popd

        # Run validation and verification on release assets before
        # we actually do the release.
        debug "running release validation for %s@%s" "${product}" "${version}"
        hashicorp_release_validate "${directory}"
        debug "running release verification for %s@%s" "${product}" "${version}"
        hashicorp_release_verify "${directory}"

        # Now that the assets have been validated and verified,
        # peform the release setps
        debug "generating release metadata for %s@%s" "${product}" "${version}"
        hashicorp_release_generate_release_metadata "${version}" "${directory}"
        debug "uploading release artifacts to staging for %s@%s" "${product}" "${version}"
        hashicorp_release_upload_to_staging "${product}" "${version}" "${directory}"
        debug "promoting release to production for %s@%s" "${product}" "${version}"
        hashicorp_release_promote_to_production "${product}" "${version}"

        printf "HashiCorp release created (%s@%s)\n" "${product}" "${version}"
    else
        printf "hashicorp release not published, already exists (%s@%s)\n" "${product}" "${version}"
    fi

    # Send a notification to update the package repositories
    # with the new release.
    debug "sending packaging notification for %s@%s" "${product}" "${version}"
    hashicorp_release_sns_publish "${product}"
}

# Check if gem version is already published to RubyGems
#
# $1: Name of RubyGem
# $2: Verision of RubyGem
# $3: Custom gem server to search (optional)
function is_version_on_rubygems() {
    local name="${1}"
    local version="${2}"
    local gemstore="${3}"

    if [ -z "${name}" ]; then
        failure "Name is required for version check on %s" "${gemstore:-RubyGems.org}"
    fi

    if [ -z "${version}" ]; then
        failure "Version is required for version check on %s" "${gemstore:-RubyGems.org}"
    fi

    debug "checking rubygem %s at version %s is currently published" "${name}" "${version}"
    local cmd_args=()
    if [ -n "${gemstore}" ]; then
        debug "checking rubygem publication at custom source: %s" "${gemstore}"
        cmd_args+=("--clear-sources" "--source" "${gemstore}")
    fi
    cmd_args+=("--remote" "--exact" "--all")

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
            debug "rubygem %s at version %s was found" "${name}" "${version}"
            break
        fi
    done
    IFS="${oifs}"
    return $r
}

# Check if gem version is already published to hashigems
#
# $1: Name of RubyGem
# $2: Verision of RubyGem
function is_version_on_hashigems() {
    is_version_on_rubygems "${1}" "${2}" "https://gems.hashicorp.com"
}

# Build and release project gem to RubyGems
function publish_to_rubygems() {
    if [ -z "${RUBYGEMS_API_KEY}" ]; then
        failure "RUBYGEMS_API_KEY is required for publishing to RubyGems.org"
    fi

    local gem_file="${1}"

    if [ -z "${gem_file}" ]; then
        failure "RubyGem file is required for publishing to RubyGems.org"
    fi

    if [ ! -f "${gem_file}" ]; then
        failure "Path provided does not exist or is not a file (%s)" "${gem_file}"
    fi

    export GEM_HOST_API_KEY="${RUBYGEMS_API_KEY}"
    wrap gem push "${gem_file}" ||
        failure "Failed to publish RubyGem at '%s' to RubyGems.org" "${gem_file}"
}

# Publish gem to the hashigems repository
#
# $1: Path to gem file to publish
function publish_to_hashigems() {
    local path="${1}"
    if [ -z "${path}" ]; then
        failure "Path to built gem required for publishing to hashigems"
    fi

    debug "publishing '%s' to hashigems" "${path}"

    # Define all the variables we'll need
    local user_bin
    local reaper
    local invalid
    local invalid_id

    wrap_stream gem install --user-install --no-document reaper-man \
        "Failed to install dependency for hashigem generation"
    user_bin="$(ruby -e 'puts Gem.user_dir')/bin"
    reaper="${user_bin}/reaper-man"

    debug "using reaper-man installation at: %s" "${reaper}"

    # Create a temporary directory to work from
    local tmpdir
    tmpdir="$(mktemp -d -p ./)" ||
        failure "Failed to create working directory for hashigems publish"
    mkdir -p "${tmpdir}/hashigems/gems" ||
        failure "Failed to create gems directory"
    wrap cp "${path}" "${tmpdir}/hashigems/gems" \
        "Failed to copy gem to working directory"
    pushd "${tmpdir}"

    # Run quick test to ensure bucket is accessible
    wrap aws s3 ls "${HASHIGEMS_METADATA_BUCKET}" \
        "Failed to access hashigems asset bucket"

    # Grab our remote metadata. If the file doesn't exist, that is always an error.
    debug "fetching hashigems metadata file from %s" "${HASHIGEMS_METADATA_BUCKET}"
    wrap aws s3 cp "${HASHIGEMS_METADATA_BUCKET}/vagrant-rubygems.list" ./ \
        "Failed to retrieve hashigems metadata list"

    # Add the new gem to the metadata file
    debug "adding new gem to the metadata file"
    wrap_stream "${reaper}" package add -S rubygems -p vagrant-rubygems.list ./hashigems/gems/*.gem \
        "Failed to add new gem to hashigems metadata list"
    # Generate the repository
    debug "generating the new hashigems repository content"
    wrap_stream "${reaper}" repo generate -p vagrant-rubygems.list -o hashigems -S rubygems \
        "Failed to generate the hashigems repository"
    # Upload the updated repository
    pushd ./hashigems
    debug "uploading new hashigems repository content to %s" "${HASHIGEMS_PUBLIC_BUCKET}"
    wrap_stream aws s3 sync . "${HASHIGEMS_PUBLIC_BUCKET}" \
        "Failed to upload the hashigems repository"
    # Store the updated metadata
    popd
    debug "uploading updated hashigems metadata file to %s" "${HASHIGEMS_METADATA_BUCKET}"
    wrap_stream aws s3 cp vagrant-rubygems.list "${HASHIGEMS_METADATA_BUCKET}/vagrant-rubygems.list" \
        "Failed to upload the updated hashigems metadata file"

    # Invalidate cloudfront so the new content is available
    local invalid
    debug "invalidating hashigems cloudfront distribution (%s)" "${HASHIGEMS_CLOUDFRONT_ID}"
    invalid="$(aws cloudfront create-invalidation --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --paths "/*")" ||
        failure "Invalidation of hashigems CDN distribution failed"
    local invalid_id
    invalid_id="$(printf '%s' "${invalid}" | jq -r ".Invalidation.Id")"
    if [ -z "${invalid_id}" ]; then
        failure "Failed to determine the ID of the hashigems CDN invalidation request"
    fi
    debug "hashigems cloudfront distribution invalidation identifer - %s" "${invalid_id}"

    # Wait for the invalidation process to complete
    debug "starting wait for hashigems cloudfront distribution invalidation to complete (id: %s)" "${invalid_id}"
    wrap aws cloudfront wait invalidation-completed --distribution-id "${HASHIGEMS_CLOUDFRONT_ID}" --id "${invalid_id}" \
        "Failure encountered while waiting for hashigems CDN invalidation request to complete (ID: ${invalid_id})"
    debug "hashigems cloudfront distribution invalidation complete (id: %s)" "${invalid_id}"

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
    printf "%s" "${s##*origin/}"
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
        if [ -n "${file_content}" ]; then
            message="${message}\n\n\`\`\`\n${file_content}\n\`\`\`"
        fi
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

    debug "sending slack message with payload: %s" "${payload}"
    if ! curl -SsL --fail -X POST -H "Content-Type: application/json" -d "${payload}" "${webhook}"; then
        echo "ERROR: Failed to send slack notification" >&2
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

    if [ -z "${tool_name}" ]; then
        failure "Repository name is required for hashicorp tool install"
    fi

    debug "installing hashicorp tool: %s" "${tool_name}"

    # Swap out repository to force correct github token
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo}"

    tmp="$(mktemp -d --tmpdir vagrantci-XXXXXX)" ||
        failure "Failed to create temporary working directory"
    pushd "${tmp}"

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

    release_content=$(github_request -H "Content-Type: application/json" \
        "https://api.github.com/repos/hashicorp/${tool_name}/releases/latest") ||
      failure "Failed to request latest releases for hashicorp/${tool_name}"

    local exten
    for exten in "${extensions[@]}"; do
        for arch in "${arches[@]}"; do
            local suffix="${platform}_${arch}.${exten}"
            debug "checking for release artifact with suffix: %s" "${suffix}"
            asset=$(printf "%s" "${release_content}" | jq -r \
                '.assets[] | select(.name | contains("'"${suffix}"'")) | .url')
            if [ -n "${asset}" ]; then
                debug "release artifact found: %s" "${asset}"
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

    debug "tool artifact match found for install: %s" "${asset}"

    github_request -o "${tool_name}.${exten}" \
        -H "Accept: application/octet-stream" "${asset}" ||
        "Failed to download latest release for hashicorp/${tool_name}"

    if [ "${exten}" = "zip" ]; then
        wrap unzip "${tool_name}.${exten}" \
            "Failed to unpack latest release for hashicorp/${tool_name}"
    else
        wrap tar xf "${tool_name}.${exten}" \
            "Failed to unpack latest release for hashicorp/${tool_name}"
    fi

    rm -f "${tool_name}.${exten}"

    local files=( ./* )
    wrap chmod 0755 ./* \
        "Failed to change mode on latest release for hashicorp/${tool_name}"

    wrap mv ./* "${ci_bin_dir}" \
        "Failed to install latest release for hashicorp/${tool_name}"

    debug "new files added to path: %s" "${files[*]}"
    popd
    rm -rf "${tmp}"

    repository="${repository_bak}" # restore the repository value
}

# Install tool from GitHub releases. It will fetch the latest release
# of the tool and install it. The proper release artifact will be matched
# by a "linux_amd64" string. This command is best effort and may not work.
#
# $1: Organization name
# $2: Repository name
# $3: Tool name (optional)
function install_github_tool() {
    local org_name="${1}"
    local r_name="${2}"
    local tool_name="${3}"

    if [ -z "${tool_name}" ]; then
        tool_name="${r_name}"
    fi

    local asset release_content tmp
    local artifact_list artifact basen

    tmp="$(mktemp -d --tmpdir vagrantci-XXXXXX)" ||
        failure "Failed to create temporary working directory"
    pushd "${tmp}"

    debug "installing github tool %s from %s/%s" "${tool_name}" "${org_name}" "${r_name}"

    release_content=$(github_request -H "Content-Type: application/json" \
        "https://api.github.com/repos/${org_name}/${r_name}/releases/latest") ||
        failure "Failed to request latest releases for ${org_name}/${r_name}"

    asset=$(printf "%s" "${release_content}" | jq -r \
        '.assets[] | select( ( (.name | contains("amd64")) or (.name | contains("x86_64")) or (.name | contains("x86-64")) ) and (.name | contains("linux")) and (.name | endswith("sha256") | not) and (.name | endswith("sig") | not))  | .url') ||
        failure "Failed to detect latest release for ${org_name}/${r_name}"

    artifact="${asset##*/}"
    github_request -o "${artifact}" -H "Accept: application/octet-stream" "${asset}" ||
        "Failed to download latest release for ${org_name}/${r_name}"

    basen="${artifact##*.}"
    if [ "${basen}" = "zip" ]; then
        wrap unzip "${artifact}" \
            "Failed to unpack latest release for ${org_name}/${r_name}"
        rm -f "${artifact}"
    elif [ -n "${basen}" ]; then
        wrap tar xf "${artifact}" \
            "Failed to unpack latest release for ${org_name}/${r_name}"
        rm -f "${artifact}"
    fi

    artifact_list=(./*)

    # If the artifact only contained a directory, get
    # the contents of the directory
    if [ "${#artifact_list[@]}" -eq "1" ] && [ -d "${artifact_list[0]}" ]; then
        debug "unpacked artifact contained only directory, inspecting contents"
        artifact_list=( "${artifact_list[0]}/"* )
    fi

    local tool_match tool_glob_match executable_match
    local item
    for item in "${artifact_list[@]}"; do
        if [ "${item##*/}" = "${tool_name}" ]; then
            debug "tool name match found: %s" "${item}"
            tool_match="${item}"
        elif [ -e "${item}" ]; then
            debug "executable match found: %s" "${item}"
            executable_match="${item}"
        elif [[ "${item}" = "${tool_name}"* ]]; then
            debug "tool name glob match found: %s" "${item}"
            tool_glob_match="${item}"
        fi
    done

    # Install based on best match to worst match
    if [ -n "${tool_match}" ]; then
        debug "installing %s from tool name match (%s)" "${tool_name}" "${tool_match}"
        mv -f "${tool_match}" "${ci_bin_dir}/${tool_name}" ||
            "Failed to install latest release of %s from %s/%s" "${tool_name}" "${org_name}" "${r_name}"
    elif [ -n "${tool_glob_match}" ]; then
        debug "installing %s from tool name glob match (%s)" "${tool_name}" "${tool_glob_match}"
        mv -f "${tool_glob_match}" "${ci_bin_dir}/${tool_name}" ||
            "Failed to install latest release of %s from %s/%s" "${tool_name}" "${org_name}" "${r_name}"
    elif [ -n "${executable_match}" ]; then
        debug "installing %s from executable file match (%s)" "${tool_name}" "${executable_match}"
        mv -f "${executable_match}" "${ci_bin_dir}/${tool_name}" ||
            "Failed to install latest release of %s from %s/%s" "${tool_name}" "${org_name}" "${r_name}"
    else
        failure "Failed to locate tool '%s' in latest release from %s/%s" "${org_name}" "${r_name}"
    fi

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
# $1: repository name
# $2: release tag name
# $3: artifact pattern (optional, all artifacts downloaded if omitted)
function github_release_assets() {
    local req_args
    req_args=()

    local  asset_pattern
    local release_repo="${1}"
    local release_name="${2}"
    local asset_pattern="${3}"

    # Swap out repository to force correct github token
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo}"

    req_args+=("Content-Type: application/json")
    req_args+=("https://api.github.com/repos/${repository}/releases/tags/${release_name}")

    debug "fetching release asset list for release %s on %s" "${release_name}" "${repository}"

    local release_content
    release_content=$(github_request "${req_args[@]}") ||
        failure "Failed to request release (${release_name}) for ${repository}"

    local query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        debug "applying release asset list filter %s" "${asset_pattern}"
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    local asset_list
    asset_list=$(printf "%s" "${release_content}" | jq -r "${query} | .url") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    local name_list
    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${release_repo}"

    req_args=()
    req_args+=("Accept: application/octet-stream")

    local assets asset_names
    readarray -t assets <  <(printf "%s" "${asset_list}")
    readarray -t asset_names < <(printf "%s" "${name_list}")

    local idx
    for ((idx=0; idx<"${#assets[@]}"; idx++ )); do
        local asset="${assets[$idx]}"
        local artifact="${asset_names[$idx]}"

        github_request "${req_args[@]}" -o "${artifact}" "${asset}" ||
            "Failed to download asset (${artifact}) in release ${release_name} for ${repository}"
        printf "downloaded release asset %s from release %s on %s" "${artifact}" "${release_name}" "${repository}"
    done

    repository="${repository_bak}" # restore the repository value
}

# Basic helper to create a GitHub prerelease
#
# $1: repository name
# $2: tag name for release
# $3: path to artifact(s) - single file or directory
function github_prerelease() {
    local prerelease_repo="${1}"
    local tag_name="${2}"
    local artifacts="${3}"

    if [ -z "${prerelease_repo}" ]; then
        failure "Name of repository required for prerelease release"
    fi

    if [ -z "${tag_name}" ]; then
        failure "Name is required for prerelease release"
    fi

    if [ -z "${artifacts}" ]; then
        failure "Artifacts path is required for prerelease release"
    fi

    if [ ! -e "${artifacts}" ]; then
        failure "No artifacts found at provided path (${artifacts})"
    fi

    local prerelease_target="${repo_owner}/${prerelease_repo}"

    # Create the prerelease
    local response
    response="$(github_create_release -p -t "${tag_name}" -o "${repo_owner}" -r "${prerelease_repo}" )" ||
        failure "Failed to create prerelease on %s/%s" "${repo_owner}" "${prerelease_repo}"

    # Extract the release ID from the response
    local release_id
    release_id="$(printf "%s" "${response}" | jq -r '.id')" ||
        failure "Failed to extract prerelease ID from response for ${tag_name} on ${prerelease_target}"

    github_upload_release_artifacts "${prerelease_repo}" "${release_id}" "${artifacts}"

}

# Upload artifacts to a release
#
# $1: target repository name
# $2: release ID
# $3: path to artifact(s) - single file or directory
function github_upload_release_artifacts() {
    local target_repo_name="${1}"
    local release_id="${2}"
    local artifacts="${3}"

    if [ -z "${target_repo_name}" ]; then
        failure "Repository name required for release artifact upload"
    fi

    if [ -z "${release_id}" ]; then
        failure "Release ID require for release artifact upload"
    fi

    if [ -z "${artifacts}" ]; then
        failure "Artifacts required for release artifact upload"
    fi

    if [ ! -e "${artifacts}" ]; then
        failure "No artifacts found at provided path for release artifact upload (%s)" "${artifacts}"
    fi

    # Swap out repository to force correct github token
    local repository_bak="${repository}"
    repository="${repo_owner}/${target_repo_name}"

    local req_args=("-X" "POST" "-H" "Content-Type: application/octet-stream")

    # Now upload the artifacts to the draft release
    local artifact_name
    if [ -f "${artifacts}" ]; then
        debug "uploading %s to release ID %s on %s" "${artifact}" "${release_id}" "${repository}"
        artifact_name="${artifacts##*/}"
        req_args+=("https://uploads.github.com/repos/${repository}/releases/${release_id}/assets?name=${artifact_name}"
                   "--data-binary" "@${artifacts}")
        if ! github_request "${req_args[@]}" > /dev/null ; then
            failure "Failed to upload artifact '${artifacts}' to draft release on ${repository}"
        fi
        printf "Uploaded release artifact: %s\n" "${artifact_name}" >&2
        # Everything is done so get on outta here
        return 0
    fi

    # Push into the directory
    pushd "${artifacts}"

    local artifact_path
    # Walk through each item and upload
    for artifact_path in * ; do
        if [ ! -f "${artifact_path}" ]; then
            debug "skipping '%s' as it is not a file" "${artifact_path}"
            continue
        fi
        artifact_name="${artifact_path##*/}"
        debug "uploading %s/%s to release ID %s on %s" "${artifacts}" "${artifact_name}" "${release_id}" "${repository}"
        local r_args=( "${req_args[@]}" )
        r_args+=("https://uploads.github.com/repos/${repository}/releases/${release_id}/assets?name=${artifact_name}"
                   "--data-binary" "@${artifact_path}")
        if ! github_request "${r_args[@]}" > /dev/null ; then
            failure "Failed to upload artifact '${artifact_name}' in '${artifacts}' to draft release on ${repository}"
        fi
        printf "Uploaded release artifact: %s\n" "${artifact_name}" >&2
    done

    repository="${repository_bak}"
}

# Basic helper to create a GitHub draft release
#
# $1: repository name
# $2: tag name for release
# $3: path to artifact(s) - single file or directory
function github_draft_release() {
    local draft_repo="${1}"
    local tag_name="${2}"
    local artifacts="${3}"

    if [ -z "${draft_repo}" ]; then
        failure "Name of repository required for draft release"
    fi

    if [ -z "${tag_name}" ]; then
        failure "Name is required for draft release"
    fi

    if [ -z "${artifacts}" ]; then
        failure "Artifacts path is required for draft release"
    fi

    if [ ! -e "${artifacts}" ]; then
        failure "No artifacts found at provided path (%s)" "${artifacts}"
    fi

    # Create the draft release
    local response
    response="$(github_create_release -d -t "${tag_name}" -o "${repo_owner}" -r "${draft_repo}" )" ||
        failure "Failed to create draft release on %s" "${repo_owner}/${draft_repo}"

    # Extract the release ID from the response
    local release_id
    release_id="$(printf "%s" "${response}" | jq -r '.id')" ||
        failure "Failed to extract draft release ID from response for %s on %s" "${tag_name}" "${repo_owner}/${draft_repo}"

    github_upload_release_artifacts "${draft_repo}" "${release_id}" "${artifacts}"
}

# Create a GitHub release
#
# -b BODY - body of release
# -c COMMITISH - commitish of release
# -n NAME - name of the release
# -o OWNER - repository owner (required)
# -r REPO - repository name (required)
# -t TAG_NAME - tag name for release (required)
# -d - draft release
# -p - prerelease
# -g - generate release notes
# -m - make release latest
#
# NOTE: Artifacts for release must be uploaded using `github_upload_release_artifacts`
function github_create_release() {
    local OPTIND opt owner repo tag_name
    # Values that can be null
    local body commitish name
    # Values we default
    local draft="false"
    local generate_notes="false"
    local make_latest="false"
    local prerelease="false"

    while getopts ":b:c:n:o:r:t:dpgm" opt; do
        case "${opt}" in
            "b") body="${OPTARG}" ;;
            "c") commitish="${OPTARG}" ;;
            "n") name="${OPTARG}" ;;
            "o") owner="${OPTARG}" ;;
            "r") repo="${OPTARG}" ;;
            "t") tag_name="${OPTARG}" ;;
            "d") draft="true" ;;
            "p") prerelease="true" ;;
            "g") generate_notes="true" ;;
            "m") make_latest="true" ;;
            *) failure "Invalid flag provided to github_create_release" ;;
        esac
    done
    shift $((OPTIND-1))

    # Sanity check
    if [ -z "${owner}" ]; then
        failure "Repository owner value is required for GitHub release"
    fi

    if [ -z "${repo}" ]; then
        failure "Repository name is required for GitHub release"
    fi

    if [ -z "${tag_name}" ]; then
        failure "Tag name is required for GitHub release"
    fi

    # If no name is provided, use the tag name value
    if [ -z "${name}" ]; then
        name="${tag_name}"
    fi

    # shellcheck disable=SC2016
    local payload_template='{tag_name: $tag_name, draft: $draft, prerelease: $prerelease, generate_release_notes: $generate_notes, make_latest: $make_latest'
    local jq_args=("-n"
                   "--arg" "tag_name" "${tag_name}"
                   "--arg" "make_latest" "${make_latest}"
                   "--argjson" "draft" "${draft}"
                   "--argjson" "generate_notes" "${generate_notes}"
                   "--argjson" "prerelease" "${prerelease}"
                  )

    if [ -n "${commitish}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', target_commitish: $commitish'
        jq_args+=("--arg" "commitish" "${commitish}")
    fi
    if [ -n "${name}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', name: $name'
        jq_args+=("--arg" "name" "${name}")
    fi
    if [ -n "${body}" ]; then
        # shellcheck disable=SC2016
        payload_template+=', body: $body'
        jq_args+=("--arg" "body" "${body}")
    fi
    payload_template+='}'

    # Generate the payload
    local payload
    payload="$(jq "${jq_args[@]}" "${payload_template}" )" ||
        failure "Could not generate GitHub release JSON payload"

    local target_repo="${owner}/${repo}"
    # Set repository to get correct token behavior on request
    local repository_bak="${repository}"
    repository="${target_repo}"

    # Craft our request arguments
    local req_args=("-X" "POST" "https://api.github.com/repos/${target_repo}/releases" "-d" "${payload}")

    # Create the draft release
    local response
    if ! response="$(github_request "${req_args[@]}")"; then
        failure "Could not create github release on ${target_repo}"
    fi

    # Restore the repository
    repository="${repository_bak}"

    local rel_type
    if [ "${draft}" = "true" ]; then
        rel_type="draft release"
    elif [ "${prerelease}" = "true" ]; then
        rel_type="prerelease"
    else
        rel_type="release"
    fi

    # Report new draft release was created
    printf "New %s '%s' created on '%s'\n" "${rel_type}" "${tag_name}" "${target_repo}" >&2

    # Print the response
    printf "%s" "${response}"
}

# Check if a github release exists by tag name
# NOTE: This can be used for release and prerelease checks.
#       Draft releases must use the github_draft_release_exists
#       function.
#
# $1: repository name
# $2: release tag name
function github_release_exists() {
    local release_repo="${1}"
    local release_name="${2}"

    if [ -z "${release_repo}" ]; then
        failure "Repository name required for release lookup"
    fi
    if [ -z "${release_name}" ]; then
        failure "Release name required for release lookup"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo}"

    local result="1"
    if github_request \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${repository}/releases/tags/${release_name}" > /dev/null; then
        debug "release '${release_name}' found in ${repository}"
        result="0"
    else
        debug "release '${release_name}' not found in ${repository}"
    fi

    # Restore repository value
    repository="${repository_bak}"

    return "${result}"
}

# Check if a draft release exists by name
#
# $1: repository name
# $2: release name
function github_draft_release_exists() {
    local release_repo="${1}"
    local release_name="${2}"

    if [ -z "${release_repo}" ]; then
        failure "Repository name required for draft release lookup"
    fi
    if [ -z "${release_name}" ]; then
        failure "Release name required for draft release lookup"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo}"

    local page=$((1))
    local release_content

    while [ -z "${release_content}" ]; do
        local release_list
        release_list="$(github_request \
            -H "Content-Type: application/json" \
            "https://api.github.com/repos/${repository}/releases?per_page=100&page=${page}")" ||
            failure "Failed to request releases list for ${repository}"

        # If there's no more results, just bust out of the loop
        if [ "$(jq 'length' <( printf "%s" "${release_list}" ))" -lt "1" ]; then
            break
        fi

        query="$(printf '.[] | select(.name == "%s")' "${release_name}")"

        release_content=$(printf "%s" "${release_list}" | jq -r "${query}")

        ((page++))
    done

    # Restore the $repository value
    repository="${repository_bak}"

    if [ -z "${release_content}" ]; then
        debug "did not locate draft release named %s for %s" "${release_name}" "${repo_owner}/${release_repo}"
        return 1
    fi

    debug "found draft release name %s in %s" "${release_name}" "${repo_owner}/${release_repo}"
    return 0
}

# Download artifact(s) from GitHub draft release. A draft release is not
# attached to a tag and therefore is referenced by the release name directly.
# The artifact pattern is simply a substring that is matched against the
# artifact download URL. Artifact(s) will be downloaded to the working directory.
#
# $1: repository name
# $2: release name
# $3: artifact pattern (optional, all artifacts downloaded if omitted)
function github_draft_release_assets() {
    local release_repo_name="${1}"
    local release_name="${2}"
    local asset_pattern="${3}"

    if [ -z "${release_repo_name}" ]; then
        failure "Repository name is required for draft release asset fetching"
    fi
    if [ -z "${release_name}" ]; then
        failure "Draft release name is required for draft release asset fetching"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo_name}"

    local page=$((1))
    local release_content query
    while [ -z "${release_content}" ]; do
        local release_list
        release_list=$(github_request -H "Content-Type: application/json" \
            "https://api.github.com/repos/${repository}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for ${repository}"

        # If there's no more results, just bust out of the loop
        if [ "$(jq 'length' <( printf "%s" "${release_list}" ))" -lt "1" ]; then
            debug "did not locate draft release named %s in %s" "${release_name}" "${repository}"
            break
        fi

        query="$(printf '.[] | select(.name == "%s")' "${release_name}")"
        release_content=$(printf "%s" "${release_list}" | jq -r "${query}")

        ((page++))
    done

    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        debug "apply pattern filter to draft assets: %s" "${asset_pattern}"
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    local asset_list
    asset_list=$(printf "%s" "${release_content}" | jq -r "${query} | .url") ||
        failure "Failed to detect asset in release (${release_name}) for ${repository}"

    local name_list
    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${repository}"

    debug "draft release assets list: %s" "${name_list}"

    local assets asset_names
    readarray -t assets <  <(printf "%s" "${asset_list}")
    readarray -t asset_names < <(printf "%s" "${name_list}")

    if [ "${#assets[@]}" -ne "${#asset_names[@]}" ]; then
        failure "Failed to match download assets with names in release list for ${repository}"
    fi

    local idx
    for ((idx=0; idx<"${#assets[@]}"; idx++ )); do
        local asset="${assets[$idx]}"
        local artifact="${asset_names[$idx]}"
        github_request -o "${artifact}" \
            -H "Accept: application/octet-stream" "${asset}" ||
            "Failed to download asset in release (${release_name}) for ${repository} - ${artifact}"

        printf "downloaded draft release asset at %s\n" "${artifact}" >&2
    done

    repository_bak="${repository}" # restore repository value
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
    local release_reponame="${1}"
    local release_name="${2}"
    local asset_pattern="${3}"

    if [ -z "${release_reponame}" ]; then
        failure "Repository name is required for draft release assets names"
    fi

    if [ -z "${release_name}" ]; then
        failure "Release name is required for draft release asset names"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_reponame}"

    local page=$((1))
    local release_content query
    while [ -z "${release_content}" ]; do
        local release_list
        release_list=$(github_request H "Content-Type: application/json" \
            "https://api.github.com/repos/${repository}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for ${repository}"

        # If there's no more results, just bust out of the loop
        if [ "$(jq 'length' <( printf "%s" "${release_list}" ))" -lt "1" ]; then
            debug "did not locate draft release named %s in %s" "${release_name}" "${repository}"
            break
        fi

        query="$(printf '.[] | select(.name == "%s")' "${release_name}")"
        release_content=$(printf "%s" "${release_list}" | jq -r "${query}")

        ((page++))
    done

    query=".assets[]"
    if [ -n "${asset_pattern}" ]; then
        debug "apply pattern filter to draft assets: %s" "${asset_pattern}"
        query+="$(printf ' | select(.name | contains("%s"))' "${asset_pattern}")"
    fi

    local name_list
    name_list=$(printf "%s" "${release_content}" | jq -r "${query} | .name") ||
        failure "Failed to detect asset in release (${release_name}) for ${repository}"

    debug "draft release assets list: %s" "${name_list}"

    local asset_names
    readarray -t asset_names < <(printf "%s" "${name_list}")

    local idx
    for ((idx=0; idx<"${#asset_names[@]}"; idx++ )); do
        local artifact="${asset_names[$idx]}"
        touch "${artifact}" ||
            failure "Failed to touch release asset at path: %s" "${artifact}"
        printf "touched draft release asset at %s\n" "${artifact}" >&2
    done

    repository_bak="${repository}" # restore repository value
}

# Delete a github release by tag name
# NOTE: Releases and prereleases can be deleted using this
#       function. For draft releases use github_delete_draft_release
#
# $1: tag name of release
# $2: repository name (optional, defaults to current repository name)
function github_delete_release() {
    local release_name="${1}"
    local release_repo="${2:-$repo_name}"

    if [ -z "${release_name}" ]; then
        failure "Release name is required for deletion"
    fi
    if [ -z "${release_repo}" ]; then
        failure "Repository is required for release deletion"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${release_repo}"

    # Fetch the release first
    local release
    release="$(github_request \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${repository}/releases/tags/${release_name}")" ||
        failure "Failed to fetch release information for '${release_name}' in ${repository}"

    # Get the release id to reference in delete request
    local rel_id
    rel_id="$(jq -r '.id' <( printf "%s" "${release}" ) )" ||
        failure "Failed to read release id for '${release_name}' in ${repository}"

    debug "deleting github release '${release_name}' in ${repository} with id ${rel_id}"

    # Send the deletion request
    github_request \
        -X "DELETE" \
        -H "Accept: application/vnd.github+json" \
        "https://api.github.com/repos/${repository}/releases/${rel_id}" > /dev/null ||
        failure "Failed to delete release '${release_name}' in ${repository}"

    # Restore repository value
    repository="${repository_bak}"
}

# Delete draft release with given name
#
# $1: name of draft release
# $2: repository name (optional, defaults to current repository name)
function github_delete_draft_release() {
    local draft_name="${1}"
    local delete_repo="${2:-$repo_name}"

    if [ -z "${draft_name}" ]; then
        failure "Draft name is required for deletion"
    fi

    if [ -z "${delete_repo}" ]; then
        failure "Repository is required for draft deletion"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${delete_repo}"

    local draft_ids=()
    local page=$((1))
    while true; do
        local release_list list_length
        release_list=$(github_request -H "Content-Type: application/json" \
            "https://api.github.com/repos/${repository}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for draft deletion on ${repository}"
        list_length="$(jq 'length' <( printf "%s" "${release_list}" ))" ||
            failure "Failed to calculate release length for draft deletion on ${repository}"

        # If the list is empty then there are no more releases to process
        if [ -z "${list_length}" ] || [ "${list_length}" -lt 1 ]; then
            debug "no releases returned for page %d in repository %s" "${page}" "${repository}"
            break
        fi

        local entry i release_draft release_id release_name
        for (( i=0; i < "${list_length}"; i++ )); do
            entry="$(jq ".[$i]" <( printf "%s" "${release_list}" ))" ||
                failure "Failed to read entry for draft deletion on ${repository}"
            release_draft="$(jq -r '.draft' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry draft for draft deletion on ${repository}"
            release_id="$(jq -r '.id' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry ID for draft deletion on ${repository}"
            release_name="$(jq -r '.name' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry name for draft deletion on ${repository}"

            # If the names don't match, skip
            if [ "${release_name}" != "${draft_name}" ]; then
                debug "skipping release deletion, name mismatch (%s != %s)" "${release_name}" "${draft_name}"
                continue
            fi

            # If the release is not a draft, fail
            if [ "${release_draft}" != "true" ]; then
                debug "skipping release '%s' (ID: %s) from '%s' - release is not a draft" "${draft_name}" "${release_id}" "${repository}"
                continue
            fi

            # If we are here, we found a match
            draft_ids+=( "${release_id}" )
        done
        ((page++))
    done

    # If no draft ids were found, the release was not found
    # so we can just return success
    if [ "${#draft_ids[@]}" -lt "1" ]; then
        debug "no draft releases found matching name %s in %s" "${draft_name}" "${repository}"
        repository="${repository_bak}" # restore repository value before return
        return 0
    fi

    # Still here? Okay! Delete the draft(s)
    local draft_id
    for draft_id in "${draft_ids[@]}"; do
        info "Deleting draft release %s from %s (ID: %d)\n" "${draft_name}" "${repository}" "${draft_id}"
        github_request -X DELETE "https://api.github.com/repos/${delete_repo}/releases/${draft_id}" ||
            failure "Failed to prune draft release ${draft_name} from ${repository}"
    done

    repository="${repository_bak}" # restore repository value before return
}

# Delete prerelease with given name
#
# $1: tag name of prerelease
# $2: repository name (optional, defaults to current repository name)
function github_delete_prerelease() {
    local tag_name="${1}"
    local delete_repo="${2:-$repo_name}"

    if [ -z "${tag_name}" ]; then
        failure "Tag name is required for deletion"
    fi

    if [ -z "${delete_repo}" ]; then
        failure "Repository is required for prerelease deletion"
    fi

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${delete_repo}"

    local prerelease
    prerelease=$(github_request -H "Content-Type: application/vnd.github+json" \
        "https://api.github.com/repos/${repository}/releases/tags/${tag_name}") ||
        failure "Failed to get prerelease %s from %s" "${tag_name}" "${repository}"
    local prerelease_id
    prerelease_id="$(jq -r '.id' <( printf "%s" "${prerelease}" ))" ||
        failure "Failed to read prerelease ID for %s on %s" "${tag_name}" "${repository}"
    local is_prerelease
    is_prerelease="$(jq -r '.prerelease' <( printf "%s" "${prerelease}" ))" ||
        failure "Failed to read prerelease status for %s on %s" "${tag_name}" "${repository}"

    # Validate the matched release is a prerelease
    if [ "${is_prerelease}" != "true" ]; then
        failure "Prerelease %s on %s is not marked as a prerelease, cannot delete" "${tag_name}" "${repository}"
    fi

    info "Deleting prerelease %s from repository %s" "${tag_name}" "${repository}"
    github_request -X DELETE "https://api.github.com/repos/${repository}/releases/${prerelease_id}" ||
        failure "Failed to delete prerelease %s from %s" "${tag_name}" "${repository}"

    repository="${repository_bak}" # restore repository value before return
}

# Delete any draft releases that are older than the
# given number of days
#
# $1: days
# $2: repository name (optional, defaults to current repository name)
function github_draft_release_prune() {
    github_release_prune "draft" "${@}"
}

# Delete any prereleases that are older than the
# given number of days
#
# $1: days
# $2: repository name (optional, defaults to current repository name)
function github_prerelease_prune() {
    github_release_prune "prerelease" "${@}"
}

# Delete any releases of provided type that are older than the
# given number of days
#
# $1: type (prerelease or draft)
# $2: days
# $3: repository name (optional, defaults to current repository name)
function github_release_prune() {
    local prune_type="${1}"
    if [ -z "${prune_type}" ]; then
        failure "Type is required for release pruning"
    fi
    if [ "${prune_type}" != "draft" ] && [ "${prune_type}" != "prerelease" ]; then
        failure "Invalid release pruning type provided '%s' (supported: draft or prerelease)" "${prune_type}"
    fi

    local days="${2}"
    if [ -z "${days}" ]; then
        failure "Number of days to retain is required for pruning"
    fi
    if [[ "${days}" = *[!0123456789]* ]]; then
        failure "Invalid value provided for days to retain when pruning (%s)" "${days}"
    fi

    local prune_repo="${3:-$repo_name}"
    if [ -z "${prune_repo}" ]; then
        failure "Repository name is required for pruning"
    fi

    local prune_seconds now
    now="$(date '+%s')"
    prune_seconds=$(("${now}"-("${days}" * 86400)))

    # Override repository value to get correct token automatically
    local repository_bak="${repository}"
    repository="${repo_owner}/${prune_repo}"

    debug "deleting %ss over %d days old from %s" "${prune_type}" "${days}" "${repository}"

    local page=$((1))
    while true; do
        local release_list list_length

        release_list=$(github_request -H "Accept: application/vnd.github+json" \
            "https://api.github.com/repos/${repository}/releases?per_page=100&page=${page}") ||
            failure "Failed to request releases list for pruning on ${repository}"

        list_length="$(jq 'length' <( printf "%s" "${release_list}" ))" ||
            failure "Failed to calculate release length for pruning on ${repository}"

        if [ -z "${list_length}" ] || [ "${list_length}" -lt "1" ]; then
            debug "releases listing page %d for %s is empty" "${page}" "${repository}"
            break
        fi

        local entry i release_type release_name release_id release_create date_check
        for (( i=0; i < "${list_length}"; i++ )); do
            entry="$(jq ".[${i}]" <( printf "%s" "${release_list}" ))" ||
                failure "Failed to read entry for pruning on %s" "${repository}"
            release_type="$(jq -r ".${prune_type}" <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry %s for pruning on %s" "${prune_type}" "${repository}"
            release_name="$(jq -r '.name' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry name for pruning on %s" "${repository}"
            release_id="$(jq -r '.id' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry ID for pruning on %s" "${repository}"
            release_create="$(jq -r '.created_at' <( printf "%s" "${entry}" ))" ||
                failure "Failed to read entry created date for pruning on %s" "${repository}"
            date_check="$(date --date="${release_create}" '+%s')" ||
                failure "Failed to parse entry created date for pruning on %s" "${repository}"

            if [ "${release_type}" != "true" ]; then
                debug "Skipping %s on %s because release is not a %s" "${release_name}" "${repository}" "${prune_type}"
                continue
            fi

            if [ "$(( "${date_check}" ))" -lt "${prune_seconds}" ]; then
                info "Deleting release %s from %s\n" "${release_name}" "${prune_repo}" >&2
                github_request -X DELETE "https://api.github.com/repos/${repository}/releases/${release_id}" ||
                    failure "Failed to prune %s %s from %s" "${prune_type}" "${release_name}" "${repository}"
            fi
        done
        ((page++))
    done

    repository="${repository_bak}" # restore the repository value
}

# Grab the correct github token to use for authentication. The
# rules used for the token to return are as follows:
#
# * only $GITHUB_TOKEN is set: $GITHUB_TOKEN
# * only $HASHIBOT_TOKEN is set: $HASHIBOT_TOKEN
#
# when both $GITHUB_TOKEN and $HASHIBOT_TOKEN are set:
#
# * $repository value matches $GITHUB_REPOSITORY: $GITHUB_TOKEN
# * $repository value does not match $GITHUB_REPOSITORY: $HASHIBOT_TOKEN
#
# Will return `0` when a token is returned, `1` when no token is returned
function github_token() {
    local gtoken

    # Return immediately if no tokens are available
    if [ -z "${GITHUB_TOKEN}" ] && [ -z "${HASHIBOT_TOKEN}" ]; then
        debug "no github or hashibot token set"
        return 1
    fi

    # Return token if only one token exists
    if [ -n "${GITHUB_TOKEN}" ] && [ -z "${HASHIBOT_TOKEN}" ]; then
        debug "only github token set"
        printf "%s\n" "${GITHUB_TOKEN}"
        return 0
    elif [ -n "${HASHIBOT_TOKEN}" ] && [ -z "${GITHUB_TOKEN}" ]; then
        debug "only hashibot token set"
        printf "%s\n" "${HASHIBOT_TOKEN}"
        return 0
    fi

    # If the $repository matches the original $GITHUB_REPOSITORY use the local token
    if [ "${repository}" = "${GITHUB_REPOSITORY}" ]; then
        debug "prefer github token "
        printf "%s\n" "${GITHUB_TOKEN}"
        return 0
    fi

    # Still here, then we send back that hashibot token
    printf "%s\n" "${HASHIBOT_TOKEN}"
    return 0
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
    local info_prefix="__info__"
    local info_tmpl="${info_prefix}:code=%{response_code}:header=%{size_header}:download=%{size_download}:file=%{filename_effective}"
    local raw_response_content

    local curl_cmd=("curl" "-w" "${info_tmpl}" "-i" "-SsL" "--fail")
    local gtoken

    # Only add the authentication token if we have one
    if gtoken="$(github_token)"; then
        curl_cmd+=("-H" "Authorization: token ${gtoken}")
    fi

    # Attach the rest of the arguments
    curl_cmd+=("${@#}")

    debug "initial request: %s" "${curl_cmd[*]}"

    # Make our request
    raw_response_content="$("${curl_cmd[@]}")" || request_exit="${?}"

    # Define the status here since we will set it in
    # the conditional below of something weird happens
    local status

    # Check if our response content starts with the info prefix.
    # If it does, we need to extract the headers from the file.
    if [[ "${raw_response_content}" = "${info_prefix}"* ]]; then
        debug "extracting request information from: %s" "${raw_response_content}"
        raw_response_content="${raw_response_content#"${info_prefix}":code=}"
        local response_code="${raw_response_content%%:*}"
        debug "response http code: %s" "${response_code}"
        raw_response_content="${raw_response_content#*:header=}"
        local header_size="${raw_response_content%%:*}"
        debug "response header size: %s" "${header_size}"
        raw_response_content="${raw_response_content#*:download=}"
        local download_size="${raw_response_content%%:*}"
        debug "response file size: %s" "${download_size}"
        raw_response_content="${raw_response_content#*:file=}"
        local file_name="${raw_response_content}"
        debug "response file name: %s" "${file_name}"
        if [ -f "${file_name}" ]; then
            # Read the headers from the file and place them in the
            # raw_response_content to be processed
            local download_fd
            exec {download_fd}<"${file_name}"
            debug "file descriptor created for header grab (source: %s): %q" "${file_name}" "${download_fd}"
            debug "reading response header content from %s" "${file_name}"
            read -r -N "${header_size}" -u "${download_fd}" raw_response_content
            # Close our descriptor
            debug "closing file descriptor: %q" "${download_fd}"
            exec {download_fd}<&-
            # Now trim the headers from the file content
            debug "trimming response header content from %s" "${file_name}"
            tail -c "${download_size}" "${file_name}" > "${file_name}.trimmed" ||
                failure "Could not trim headers from downloaded file (%s)" "${file_name}"
            mv -f "${file_name}.trimmed" "${file_name}" ||
                failure "Could not replace downloaded file with trimmed file (%s)" "${file_name}"
        else
            debug "expected file not found (%s)" "${file_name}"
            status="${response_code}"
        fi
    else
        # Since the response wasn't written to a file, trim the
        # info from the end of the response
        if [[ "${raw_response_content}" != *"${info_prefix}"* ]]; then
            debug "github request response does not include information footer"
            failure "Unexpected error encountered, partial GitHub response returned"
        fi
        raw_response_content="${raw_response_content%"${info_prefix}"*}"
    fi

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
        # strip any leading/trailing whitespace characters
        read -rd '' line <<< "${line}"

        if [ -z "${line}" ] && [[ "${status}" = "2"* ]]; then
            local start="$(( i + 1 ))"
            local remain="$(( "${#lines[@]}" - "${start}" ))"
            local response_lines=("${lines[@]:$start:$remain}")
            response_content="${response_lines[*]}"
            break
        fi

        if [[ "${line}" == "HTTP/"* ]]; then
            status="${line##* }"
            debug "http status found: %d" "${status}"
        fi
        if [[ "${line}" == "x-ratelimit-reset"* ]]; then
            ratelimit_reset="${line##*ratelimit-reset: }"
            debug "ratelimit reset time found: %s" "${ratelimit_reset}"
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
        debug "rate limiting has been detected on request"

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

    debug "locking issues that have been closed for at least %d days" "${days}"

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
                debug "Skipping %s#%s because it is already locked" "${repository}" "${issue_id}"
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
                printf "Locking issue %s#%s\n" "${repository}" "${issue_id}" >&2

                # If we have a comment to add before locking, do that now
                if [ -n "${message}" ]; then
                    local message_json
                    message_json=$(jq -n \
                        --arg msg "$(printf "%b" "${message}")" \
                        '{body: $msg}'
                        ) || failure "Failed to create issue comment JSON content for ${repository}"

                    debug "adding issue comment before locking on %s#%s" "${repository}" "${issue_id}"

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
# $1: repository name
# $2: event type (single word string)
# $n: "key=value" pairs to build payload (optional)
#
function github_repository_dispatch() {
    local drepo_name="${1}"
    local event_type="${2}"

    if [ -z "${drepo_name}" ]; then
        failure "Repository name is required for repository dispatch"
    fi

    # shellcheck disable=SC2016
    local payload_template='{"vagrant-ci": $vagrant_ci'
    local jqargs=("--arg" "vagrant_ci" "true")
    local arg
    for arg in "${@:4}"; do
        local payload_key="${arg%%=*}"
        local payload_value="${arg##*=}"
        payload_template+=", \"${payload_key}\": \$${payload_key}"
        # shellcheck disable=SC2089
        jqargs+=("--arg" "${payload_key}" "${payload_value}")
    done
    payload_template+="}"

    # NOTE: we want the arguments to be expanded below
    local payload
    payload=$(jq -n "${jqargs[@]}" "${payload_template}" ) ||
        failure "Failed to generate repository dispatch payload"

    # shellcheck disable=SC2016
    local msg_template='{event_type: $event_type, client_payload: $payload}'
    local msg
    msg=$(jq -n \
        --argjson payload "${payload}" \
        --arg event_type "${event_type}" \
        "${msg_template}" \
        ) || failure "Failed to generate repository dispatch message"

    debug "sending repository dispatch to %s/%s with payload: %s" \
        "${repo_owner}" "${drepo_name}" "${msg}"

    # Update repository value to get correct token
    local repository_bak="${repository}"
    repository="${repo_owner}/${drepo_name}"

    github_request -X "POST" \
        -H 'Accept: application/vnd.github.everest-v3+json' \
        --data "${msg}" \
        "https://api.github.com/repos/${repo_owner}/${drepo_name}/dispatches" ||
        failure "Repository dispatch to ${repo_owner}/${drepo_name} failed"

    # Restore the repository value
    repository="${repository_bak}"
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
    debug "* Running cleanup task..."
    # Always restore this value for cases where a failure
    # happened within a function while this value was in
    # a modified state
    repository="${_repository_backup}"
    cleanup
}

# Stub cleanup method which can be redefined
# within actual script
function cleanup() {
    debug "** No cleanup tasks defined"
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

if [ -n "${GITHUB_ACTIONS}" ]; then
    priv_check="$(curl "${priv_args[@]}" -s "https://api.github.com/repos/${GITHUB_REPOSITORY}" | jq .private)" ||
        failure "Repository visibility check failed"
fi

# If the value wasn't true we unset it to indicate not private. The
# repository might actually be private but we weren't supplied a
# token (or one with correct permissions) so we fallback to the safe
# assumption of not private.
if [ "${priv_check}" != "true" ]; then
    readonly is_public="1"
    readonly is_private=""
else
    # shellcheck disable=SC2034
    readonly is_public=""
    # shellcheck disable=SC2034
    readonly is_private="1"
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
