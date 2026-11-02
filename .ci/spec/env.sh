#!/usr/bin/env bash
# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT


# packet and job configuration
export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://media.giphy.com/media/yIQ5glQeheYE0/200.gif"
export SLACK_TITLE="Vagrant-Spec Test Runner"
export SLACK_CHANNEL="CLYRTANRH" # CLYRTANRH is ID of #team-vagrant-spam-channel
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-spec-ci-boxes}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-c3.small.x86,c3.medium.x86}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-la4,dc10,dc13,ny7,pa4,md2}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVagrant,InstallVirtualBox,InstallVmware,InstallVagrantVmware}"
export PACKET_EXEC_QUIET="1"
export PACKET_EXEC_PERSIST="1"
# job_id is provided by common.sh
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"

# Pass Hashibot Credentials down to packet-exec run commands so they can fetch
# private github repos during build
export PKT_HASHIBOT_USERNAME="${HASHIBOT_USERNAME}"
export PKT_HASHIBOT_TOKEN="${HASHIBOT_TOKEN}"
###
