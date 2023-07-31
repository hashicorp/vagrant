# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe "VagrantPlugins::Shell::Config" do
  let(:described_class) do
    VagrantPlugins::Shell::Plugin.components.configs[:provisioner][:shell]
  end

  let(:machine)          { double('machine', env: Vagrant::Environment.new) }
  let(:file_that_exists) { File.expand_path(__FILE__)                       }

  subject { described_class.new }

  describe "validate" do
    it "passes with no args" do
      subject.path = file_that_exists
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with string args" do
      subject.path = file_that_exists
      subject.args = "a string"
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with integer args" do
      subject.path = file_that_exists
      subject.args = 1
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with array args" do
      subject.path = file_that_exists
      subject.args = ["an", "array"]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "returns an error if args is neither a string nor an array" do
      neither_array_nor_string = Object.new

      subject.path = file_that_exists
      subject.args = neither_array_nor_string
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([
        I18n.t("vagrant.provisioners.shell.args_bad_type")
      ])
    end

    it "handles scalar array args" do
      subject.path = file_that_exists
      subject.args = ["string", 1, 2]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "returns an error if args is an array with non-scalar types" do
      subject.path = file_that_exists
      subject.args = [[1]]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([
        I18n.t("vagrant.provisioners.shell.args_bad_type")
      ])
    end

    it "returns an error if elevated_interactive is true but privileged is false" do
      subject.path = file_that_exists
      subject.powershell_elevated_interactive = true
      subject.privileged = false
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([
        I18n.t("vagrant.provisioners.shell.interactive_not_elevated")
      ])
    end

    it "returns an error if the environment is not a hash" do
      subject.env = "foo"
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to include(
        I18n.t("vagrant.provisioners.shell.env_must_be_a_hash")
      )
    end

    it "returns an error if file and script are unset" do
      subject.finalize!
      result = subject.validate(machine)
      expect(result["shell provisioner"]).to include(
        I18n.t("vagrant.provisioners.shell.no_path_or_inline")
      )
    end

    it "returns an error if inline and path are both set" do
      subject.inline = "script"
      subject.path = "script"
      result = subject.validate(machine)
      expect(result["shell provisioner"]).to include(
        I18n.t("vagrant.provisioners.shell.path_and_inline_set")
      )
    end

    it "returns no error when inline and path are unset but reset is true" do
      subject.reset = true
      subject.finalize!

      result = subject.validate(machine)
      expect(result["shell provisioner"]).to be_empty
    end

    it "returns no error when inline and path are unset but reboot is true" do
      subject.reboot = true
      subject.finalize!

      result = subject.validate(machine)
      expect(result["shell provisioner"]).to be_empty
    end

    it "returns no error if upload_path is unset" do
      subject.inline = "script"
      subject.finalize!

      result = subject.validate(machine)
      expect(result["shell provisioner"]).to be_empty
    end
  end

  describe 'finalize!' do
    it 'changes integer args into strings' do
      subject.path = file_that_exists
      subject.args = 1
      subject.finalize!

      expect(subject.args).to eq('1')
    end

    it 'changes integer args in arrays into strings' do
      subject.path = file_that_exists
      subject.args = ["string", 1, 2]
      subject.finalize!

      expect(subject.args).to eq(["string", '1', '2'])
    end

    it "no longer sets a default for upload_path" do
      subject.finalize!

      expect(subject.upload_path).to eq(nil)
    end

    context "with sensitive option enabled" do
      it 'marks environment variable values sensitive' do
        subject.env = {"KEY1" => "VAL1", "KEY2" => "VAL2"}
        subject.sensitive = true

        expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("VAL1")
        expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("VAL2")
        subject.finalize!
      end
    end

    context "with sensitive option disabled" do
      it 'does not mark environment variable values sensitive' do
        subject.env = {"KEY1" => "VAL1", "KEY2" => "VAL2"}
        subject.sensitive = false

        expect(Vagrant::Util::CredentialScrubber).not_to receive(:sensitive)
        subject.finalize!
      end
    end
  end
end
