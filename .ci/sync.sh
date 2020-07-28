#!/usr/bin/env bash

csource="${BASH_SOURCE[0]}"
while [ -h "$csource" ] ; do csource="$(readlink "$csource")"; done
root="$( cd -P "$( dirname "$csource" )/../" && pwd )"

. "${root}/.ci/common.sh"

export PATH="${PATH}:${root}/.ci"

pushd "${root}" > "${output}"

if [ "${repo_name}" = "vagrant" ]; then
    remote_repository="hashicorp/vagrant-blackbox"
else
  fail "This repository is not configured to sync vagrant to mirror repository"
fi

echo "Adding remote mirror repository '${remote_repository}'..."
wrap git remote add mirror "https://${HASHIBOT_USERNAME}:${HASHIBOT_TOKEN}@github.com/${remote_repository}" \
     "Failed to add mirror '${remote_repository}' for sync"

echo "Updating configured remotes..."
wrap_stream git remote update mirror \
            "Failed to update mirror repository (${remote_repository}) for sync"

rb=$(git branch -r --list "mirror/${ident_ref}")

if [ "${rb}" != "" ]; then
    echo "Pulling ${ident_ref} from mirror..."
    wrap_stream git pull mirror "${ident_ref}" \
                "Failed to pull ${ident_ref} from mirror repository (${remote_repository}) for sync"
fi

echo "Pushing ${ident_ref} to mirror..."
wrap_stream git push mirror "${ident_ref}" \
            "Failed to sync mirror repository (${remote_repository})"
