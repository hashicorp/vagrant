# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/provisioner")

describe VagrantPlugins::DockerProvisioner::Plugin do
  subject { described_class }

  it "has valid guest capabilities" do
    subject.components.guest_capabilities.each do |guest, caps|
      caps.each do |cap|
        subject.components.guest_capabilities[guest][cap]
      end
    end
  end

end