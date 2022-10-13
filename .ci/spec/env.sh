#!/usr/bin/env bash

# packet and job configuration
export SLACK_USERNAME="Vagrant"
export SLACK_ICON="https://media.giphy.com/media/yIQ5glQeheYE0/200.gif"
export SLACK_TITLE="Vagrant-Spec Test Runner"
export PACKET_EXEC_DEVICE_NAME="${PACKET_EXEC_DEVICE_NAME:-spec-ci-boxes}"
export PACKET_EXEC_DEVICE_SIZE="${PACKET_EXEC_DEVICE_SIZE:-baremetal_0,baremetal_1,baremetal_1e}"
export PACKET_EXEC_PREFER_FACILITIES="${PACKET_EXEC_PREFER_FACILITIES:-iad1,iad2,ewr1,dfw1,dfw2,sea1,sjc1,lax1}"
export PACKET_EXEC_OPERATING_SYSTEM="${PACKET_EXEC_OPERATING_SYSTEM:-ubuntu_18_04}"
export PACKET_EXEC_PRE_BUILTINS="${PACKET_EXEC_PRE_BUILTINS:-InstallVagrant,InstallVirtualBox,InstallVmware,InstallVagrantVmware}"
export PACKET_EXEC_QUIET="1"
export PACKET_EXEC_PERSIST="1"
# job_id is provided by common.sh
export PACKET_EXEC_REMOTE_DIRECTORY="${job_id}"
export PKT_VAGRANT_CLOUD_TOKEN="${VAGRANT_CLOUD_TOKEN}"
###
