# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/windows/cap/ssh"

describe VagrantPlugins::HostWindows::Cap::SSH do
  let(:subject){ VagrantPlugins::HostWindows::Cap::SSH }
  let(:result){ Vagrant::Util::Subprocess::Result.new(exit_code, stdout, stderr) }
  let(:exit_code){ 0 }
  let(:stdout){ "" }
  let(:stderr){ "" }

  let(:key_path){ double("keypath", to_s: "keypath") }
  let(:env){ double("env") }

  before do
    allow(Vagrant::Util::PowerShell).to receive(:execute).and_return(result)
  end

  it "should execute PowerShell script" do
    expect(Vagrant::Util::PowerShell).to receive(:execute).with(
      /set_ssh_key_permissions.ps1/, "-KeyPath", key_path.to_s, any_args
    ).and_return(result)
    subject.set_ssh_key_permissions(env, key_path)
  end

  it "should return the result" do

    expect(subject.set_ssh_key_permissions(env, key_path)).to eq(result)
  end

  context "when command fails" do
    let(:exit_code){ 1 }

    it "should raise an error" do
      expect{ subject.set_ssh_key_permissions(env, key_path) }.to raise_error(Vagrant::Errors::PowerShellError)
    end
  end
end
