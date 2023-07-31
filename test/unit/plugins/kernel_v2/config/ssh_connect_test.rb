# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/ssh_connect")

describe VagrantPlugins::Kernel_V2::SSHConnectConfig do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  subject { described_class.new }

  describe "#verify_host_key" do
    it "defaults to :never" do
      subject.finalize!
      expect(subject.verify_host_key).to eq(:never)
    end

    it "should modify true value to :accepts_new_or_local_tunnel" do
      subject.verify_host_key = true
      subject.finalize!
      expect(subject.verify_host_key).to eq(:accepts_new_or_local_tunnel)
    end

    it "should modify :very value to :accept_new" do
      subject.verify_host_key = :very
      subject.finalize!
      expect(subject.verify_host_key).to eq(:accept_new)
    end

    it "should modify :secure to :always" do
      subject.verify_host_key = :secure
      subject.finalize!
      expect(subject.verify_host_key).to eq(:always)
    end
  end

  describe "#config" do
    let(:config_file) { "/path/to/config" }

    before do
      # NOTE: The machine instance must be initialized before
      #       any mocks on File are registered. Otherwise it
      #       will cause a failure attempting to create the
      #       instance
      machine
      allow(File).to receive(:file?).
        with(/#{Regexp.escape(config_file)}/).
        and_return(true)
    end

    it "defaults to nil" do
      subject.finalize!
      expect(subject.config).to be_nil
    end

    it "should return the set path" do
      subject.config = config_file
      subject.finalize!
      expect(subject.config).to eq(config_file)
    end

    it "should validate when path exists" do
      subject.config = config_file
      subject.finalize!
      machine
      expect(File).to receive(:file?).
        with(/#{Regexp.escape(config_file)}/).
        and_return(true)
      expect(subject.validate(machine)).to be_empty
    end

    it "should not validate when path does not exist" do
      subject.config = config_file
      subject.finalize!
      expect(File).to receive(:file?).
        with(/#{Regexp.escape(config_file)}/).
        and_return(false)
      expect(subject.validate(machine)).not_to be_empty
    end
  end

  describe "#remote_user" do
    let(:username) { double("username") }
    let(:remote_user) { double("remote_user") }

    it "should default to username value" do
      subject.username = username
      subject.finalize!
      expect(subject.remote_user).to eq(subject.username)
    end

    it "should be set to provided value" do
      subject.username = username
      subject.remote_user = remote_user
      subject.finalize!
      expect(subject.remote_user).to eq(remote_user)
    end
  end

  describe "#connect_timeout" do
    let(:timeout_value) { 1 }

    it "should default to the default value" do
      subject.finalize!
      expect(subject.connect_timeout).
        to eq(described_class.const_get(:DEFAULT_SSH_CONNECT_TIMEOUT))
    end


    it "should be set to provided value" do
      subject.connect_timeout = timeout_value
      subject.finalize!
      expect(subject.connect_timeout).to eq(timeout_value)
    end

    it "should cast given value to integer" do
      subject.connect_timeout = timeout_value.to_s
      subject.finalize!
      expect(subject.connect_timeout).to eq(timeout_value)
    end

    it "should properly validate" do
      subject.connect_timeout = timeout_value
      subject.finalize!
      expect(subject.validate(machine)).to be_empty
    end

    context "when value cannot be cast" do
      let(:timeout_value) { :value }

      it "should not raise an error" do
        subject.connect_timeout = timeout_value
        expect { subject.finalize! }.not_to raise_error
      end

      it "should not validate" do
        subject.connect_timeout = timeout_value
        subject.finalize!
        expect(subject.validate(machine)).not_to be_empty
      end
    end

    context "when value is less than 1" do
      let(:timeout_value) { 0 }

      it "should not raise an error" do
        subject.connect_timeout = timeout_value
        expect { subject.finalize! }.not_to raise_error
      end

      it "should not validate" do
        subject.connnect_timeout = timeout_value
        subject.finalize!
        expect(subject.validate(machine)).not_to be_empty
      end
    end
  end
end
