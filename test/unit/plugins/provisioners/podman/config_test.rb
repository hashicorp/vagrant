# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/podman/config")
require Vagrant.source_root.join("plugins/provisioners/podman/provisioner")
require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe VagrantPlugins::PodmanProvisioner::Config do
  subject { described_class.new }

  describe "#post_install_provision" do
    it "raises an error if 'podman' provisioner was provided" do
      expect {subject.post_install_provision("myprov", :type=>"podman", :inline=>"echo 'hello'")}
        .to raise_error(VagrantPlugins::PodmanProvisioner::PodmanError)
    end

    it "setups a basic provisioner" do
      prov = double()
      mock_provisioner = "mock"
      mock_provisioners = [mock_provisioner]

      allow(VagrantPlugins::Kernel_V2::VMConfig).to receive(:new).
        and_return(prov)
      allow(prov).to receive(:provision).and_return(mock_provisioners)
      allow(prov).to receive(:provisioners).and_return(mock_provisioners)

      subject.post_install_provision("myprov", :inline=>"echo 'hello'")
      expect(subject.post_install_provisioner).to eq(mock_provisioner)
    end
  end
end
