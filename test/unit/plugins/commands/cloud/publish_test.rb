# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cloud/publish")

describe VagrantPlugins::CloudCommand::Command::Publish do
  include_context "unit"

  let(:argv) { [] }
  let(:iso_env) { double("iso_env") }
  let(:account) { double("account") }
  let(:organization) { double("organization") }
  let(:box) { double("box") }
  let(:box_size) { 1 }
  let(:version) { double("version") }
  let(:provider) { double("provider") }
  let(:uploader) { double("uploader") }
  let(:ui) { Vagrant::UI::Silent.new }
  let(:upload_url) { double("upload_url") }
  let(:access_token) { double("access_token") }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(iso_env).to receive(:ui).and_return(ui)
    allow(File).to receive(:stat).with(box).
      and_return(double("box_stat", size: box_size))
    allow(VagrantCloud::Account).to receive(:new).
      with(custom_server: anything, access_token: anything).
      and_return(account)
  end

  describe "#upload_box_file" do
    before do
      allow(provider).to receive(:upload).and_yield(upload_url)
      allow(uploader).to receive(:upload!)
      allow(File).to receive(:absolute_path).and_return(box)
      allow(Vagrant::Util::Uploader).to receive(:new).and_return(uploader)
    end

    it "should get absolute path for box file" do
      expect(File).to receive(:absolute_path).and_return(box)
      subject.upload_box_file(provider, box)
    end

    it "should upload through provider" do
      expect(provider).to receive(:upload).and_return(upload_url)
      subject.upload_box_file(provider, box)
    end

    it "should create uploader with given url" do
      expect(Vagrant::Util::Uploader).to receive(:new).
        with(upload_url, any_args).and_return(uploader)
      subject.upload_box_file(provider, box)
    end

    it "should upload with PUT method by default" do
      expect(Vagrant::Util::Uploader).to receive(:new).
        with(upload_url, anything, hash_including(method: :put)).and_return(uploader)
      subject.upload_box_file(provider, box)
    end

    context "with direct upload option enabled" do
      it "should upload with PUT method when direct upload option set" do
        expect(Vagrant::Util::Uploader).to receive(:new).
          with(upload_url, anything, hash_including(method: :put)).and_return(uploader)
        subject.upload_box_file(provider, box, direct_upload: true)
      end

      context "with box size of 5GB" do
        let(:box_size) { 5368709120 }

        it "should upload using direct to storage option" do
          expect(provider).to receive(:upload).with(direct: true)
          subject.upload_box_file(provider, box, direct_upload: true)
        end
      end

      context "with box size greater than 5GB" do
        let(:box_size) { 5368709121 }

        it "should disable direct to storage upload" do
          expect(provider).to receive(:upload).with(direct: false)
          subject.upload_box_file(provider, box, direct_upload: true)
        end
      end
    end
  end

  describe "#release_version" do
    it "should release the version" do
      expect(version).to receive(:release)
      subject.release_version(version)
    end
  end

  describe "#set_box_info" do
    context "with no options set" do
      let(:options) { {} }

      it "should not modify the box" do
        subject.set_box_info(box, options)
      end
    end

    context "with options set" do
      let(:priv) { double("private") }
      let(:short_description) { double("short_description") }
      let(:description) { double("description") }

      let(:options) {
        {private: priv, description: description, short_description: short_description}
      }

      it "should set info on box" do
        expect(box).to receive(:private=).with(priv)
        expect(box).to receive(:short_description=).with(short_description)
        expect(box).to receive(:description=).with(description)
        subject.set_box_info(box, options)
      end
    end
  end

  describe "#set_version_info" do
    context "with no options set" do
      let(:options) { {} }

      it "should not modify the verison" do
        subject.set_version_info(version, options)
      end
    end

    context "with options set" do
      let(:options) { {version_description: version_description} }
      let(:version_description) { double("version_description") }

      it "should set info on version" do
        expect(version).to receive(:description=).with(version_description)
        subject.set_version_info(version, options)
      end
    end
  end

  describe "#set_provider_info" do
    context "with no options set" do
      let(:options) { {} }

      it "should not modify the provider" do
        subject.set_provider_info(provider, options)
      end
    end

    context "with options set" do
      let(:options) { {url: url, checksum: checksum, checksum_type: checksum_type} }
      let(:url) { double("url") }
      let(:checksum) { double("checksum") }
      let(:checksum_type) { double("checksum_type") }

      it "should set info on provider" do
        expect(provider).to receive(:url=).with(url)
        expect(provider).to receive(:checksum=).with(checksum)
        expect(provider).to receive(:checksum_type=).with(checksum_type)
        subject.set_provider_info(provider, options)
      end
    end
  end

  describe "load_box_version" do
    let(:box_version) { "1.0.0" }

    context "when version exists" do
      before do
        allow(box).to receive(:versions).and_return([version])
        allow(version).to receive(:version).and_return(box_version)
      end

      it "should return the existing version" do
        expect(subject.load_box_version(box, box_version)).to eq(version)
      end
    end

    context "when version does not exist" do
      let(:new_version) { double("new_version") }

      before do
        allow(box).to receive(:versions).and_return([version])
        allow(version).to receive(:version)
      end

      it "should add a new version" do
        expect(box).to receive(:add_version).with(box_version).
          and_return(new_version)
        expect(subject.load_box_version(box, box_version)).to eq(new_version)
      end
    end
  end

  describe "#load_box" do
    let(:org_name) { "org-name" }
    let(:box_name) { "my-box" }

    before do
      allow(account).to receive(:organization).with(name: org_name).
        and_return(organization)
    end

    context "when box exists" do
      before do
        allow(box).to receive(:name).and_return(box_name)
        allow(organization).to receive(:boxes).and_return([box])
      end

      it "should return the existing box" do
        expect(subject.load_box(org_name, box_name, access_token)).to eq(box)
      end
    end

    context "when box does not exist" do
      let(:new_box) { double("new_box") }

      before do
        allow(organization).to receive(:boxes).and_return([])
      end

      it "should add a new box to organization" do
        expect(organization).to receive(:add_box).with(box_name).
          and_return(new_box)
        expect(subject.load_box(org_name, box_name, access_token)).to eq(new_box)
      end
    end
  end

  context "#execute" do
    let(:iso_env) do
      # We have to create a Vagrantfile so there is a root path
      env = isolated_environment
      env.vagrantfile("")
      env.create_vagrant_env
    end
    let(:client) { double("client", token: "1234token1234") }
    let(:action_runner) { double("action_runner") }
    let(:box_path) { "path/to/the/virtualbox.box" }
    let(:full_box_path) { "/full/#{box_path}" }
    let(:box) { full_box_path }

    before do
      allow(iso_env).to receive(:action_runner).
        and_return(action_runner)
      allow(subject).to receive(:client_login).
        and_return(client)
      allow(subject).to receive(:format_box_results)

      allow(iso_env.ui).to receive(:ask).and_return("y")
      allow(File).to receive(:absolute_path).with(box_path)
        .and_return("/full/#{box_path}")
      allow(File).to receive(:file?).with(box_path)
        .and_return(true)
    end

    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "missing required arguments" do
      let(:argv) { ["vagrant/box", "1.0.0", "virtualbox"] }

      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "missing box file" do
      let(:argv) { ["vagrant/box", "1.0.0", "virtualbox", "/notreal/file.box"] }

      it "raises an exception" do
        allow(File).to receive(:file?).and_return(false)
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::BoxFileNotExist)
      end
    end

    context "with arguments" do
      let(:org_name) { "vagrant" }
      let(:box_name) { "box" }
      let(:box_version) { "1.0.0" }
      let(:box_version_provider) { "virtualbox" }

      let(:argv) { [
        "#{org_name}/#{box_name}", box_version, box_version_provider, box_path
      ] }

      before do
        allow(account).to receive(:organization).with(name: org_name).
          and_return(organization)
        allow(subject).to receive(:load_box).and_return(box)
        allow(subject).to receive(:load_box_version).and_return(version)
        allow(subject).to receive(:load_version_provider).and_return(provider)
        allow(provider).to receive(:upload)

        allow(box).to receive(:save)
      end

      it "should prompt user for confirmation" do
        expect(iso_env.ui).to receive(:ask).and_return("y")
        expect(subject.execute).to eq(0)
      end

      context "when --force option is provided" do
        before { argv << "--force" }

        it "should not prompt user for confirmation" do
          expect(iso_env.ui).not_to receive(:ask)
          expect(subject.execute).to eq(0)
        end
      end

      context "when --release option is provided" do
        before do
          argv << "--release"
        end

        it "should release box version when not released" do
          expect(version).to receive(:released?).and_return(false)
          expect(version).to receive(:release)
          expect(subject.execute).to eq(0)
        end
      end

      context "when Vagrant Cloud error is encountered" do
        before { expect(box).to receive(:save).and_raise(VagrantCloud::Error) }

        it "should return non-zero result" do
          result = subject.execute
          expect(result).not_to eq(0)
          expect(result).to be_a(Integer)
        end
      end
    end
  end
end
