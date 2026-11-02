# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/bsd/cap/ssh"

describe VagrantPlugins::HostBSD::Cap::SSH do
  let(:subject){ VagrantPlugins::HostBSD::Cap::SSH }

  let(:env){ double("env") }
  let(:key_path){ double("key_path") }

  it "should set file as user only read/write" do
    expect(key_path).to receive(:chmod).with(0600)
    subject.set_ssh_key_permissions(env, key_path)
  end
end
