# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/upload/command")

describe VagrantPlugins::CommandUpload::Command do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest", capability_host_chain: guest_chain) }
  let(:host)    { double("host", capability_host_chain: host_chain) }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:communicator) { double("communicator") }
  let(:host_chain){ [[]] }
  let(:guest_chain){ [[]] }

  let(:argv)     { [] }
  let(:config) {
    double("config")
  }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:config).and_return(config)
    allow(subject).to receive(:with_target_vms)
  end

  it "should raise invalid usage error by default" do
    expect { subject.execute }.to raise_error(Vagrant::Errors::CLIInvalidUsage)
  end

  context "when three arguments are provided" do
    let(:argv) { ["source", "destination", "guest"] }

    before { allow(File).to receive(:file?).and_return(true) }

    it "should use third argument as name of guest" do
      expect(subject).to receive(:with_target_vms).with("guest", any_args)
      subject.execute
    end

    it "should use first argument as source and second as destination" do
      allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
      expect(communicator).to receive(:upload).with("source", "destination")
      subject.execute
    end
  end

  context "when two arguments are provided" do
    let(:argv) { ["source", "ambiguous"] }
    let(:active_machines) { [] }

    before do
      allow(File).to receive(:file?).and_return(true)
      allow(iso_env).to receive(:active_machines).and_return(active_machines)
    end

    it "should use the the second argument as destination when not a machine name" do
      allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
      expect(communicator).to receive(:upload).with("source", "ambiguous")
      subject.execute
    end

    context "when active machine matches second argument" do
      let(:active_machines) { [["ambiguous"]] }

      it "should use second argument as guest name and generate destination" do
        allow(subject).to receive(:with_target_vms).with("ambiguous", any_args) { |&block| block.call machine }
        expect(communicator).to receive(:upload).with("source", "source")
        subject.execute
      end
    end
  end

  context "when single argument is provided" do
    let(:argv) { ["item"] }

    before do
      allow(File).to receive(:file?)
      allow(File).to receive(:directory?)
    end

    it "should check if source is a file" do
      expect(File).to receive(:file?).with("item").and_return(true)
      subject.execute
    end

    it "should check if source is a directory" do
      expect(File).to receive(:directory?).with("item").and_return(true)
      subject.execute
    end

    it "should raise error if source is not a directory or file" do
      expect { subject.execute }.to raise_error(Vagrant::Errors::UploadSourceMissing)
    end

    context "when source path ends with double quote" do
      let(:argv) { [".\\item\""] }

      it "should remove trailing quote" do
        expect(File).to receive(:file?).with(".\\item").and_return(true)
        subject.execute
      end
    end

    context "when source path ends with single quote" do
      let(:argv) { ['.\item\''] }

      it "should remove trailing quote" do
        expect(File).to receive(:file?).with(".\\item").and_return(true)
        subject.execute
      end
    end

    context "when source is a directory" do
      before do
        allow(File).to receive(:file?).with("item").and_return(false)
        allow(File).to receive(:directory?).with("item").and_return(true)
        allow(communicator).to receive(:upload)
        allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
      end

      it "should upload the directory" do
        expect(communicator).to receive(:upload).with(/item/, anything)
        subject.execute
      end

      it "should append separator and dot to source path for upload" do
        expect(communicator).to receive(:upload).with("item/.", anything)
        subject.execute
      end
    end

    context "when source is a file" do
      before do
        allow(File).to receive(:file?).with("item").and_return(true)
        allow(communicator).to receive(:upload)
        allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
        allow(machine).to receive(:guest).and_return(guest)
        allow(machine).to receive(:env).and_return(double("env", host: host))
        allow(guest).to receive(:capability?).and_return(true)
        allow(guest).to receive(:capability)
      end

      it "should upload the file" do
        expect(communicator).to receive(:upload).with("item", anything)
        subject.execute
      end

      it "should name destination after the source" do
        expect(communicator).to receive(:upload).with("item", "item")
        subject.execute
      end

      context "when temporary option is set" do
        before { argv << "-t" }

        it "should get temporary path for destination from guest" do
          expect(guest).to receive(:capability).with(:create_tmp_path, any_args).and_return("TMP_PATH")
          expect(communicator).to receive(:upload).with("item", "TMP_PATH")
          subject.execute
        end
      end

      context "when compress option is set" do
        before do
          argv << "-c"
          allow(guest).to receive(:capability).with(:create_tmp_path, any_args).and_return("TMP")
          allow(subject).to receive(:compress_source_zip).and_return("COMPRESS_SOURCE")
          allow(subject).to receive(:compress_source_tgz).and_return("COMPRESS_SOURCE")
          allow(FileUtils).to receive(:rm).with("COMPRESS_SOURCE")
        end

        it "should check for guest decompression" do
          expect(guest).to receive(:capability?).with(:decompress_tgz).and_return(true)
          subject.execute
        end

        it "should compress the source" do
          expect(subject).to receive(:compress_source_tgz).with("item").and_return("COMPRESS_SOURCE")
          subject.execute
        end

        it "should cleanup compressed source" do
          expect(FileUtils).to receive(:rm).with("COMPRESS_SOURCE")
          subject.execute
        end

        it "should upload the compressed source" do
          expect(communicator).to receive(:upload).with("COMPRESS_SOURCE", anything)
          subject.execute
        end

        it "should upload compressed source to temporary location" do
          expect(communicator).to receive(:upload).with("COMPRESS_SOURCE", "TMP")
          subject.execute
        end

        it "should have guest decompress file" do
          expect(guest).to receive(:capability).with(:decompress_tgz, "TMP", any_args)
          subject.execute
        end

        it "should provide destination for guest decompression of file" do
          expect(guest).to receive(:capability).with(:decompress_tgz, "TMP", "item", any_args)
          subject.execute
        end

        it "should provide the destination type for guest decompression" do
          expect(guest).to receive(:capability).with(:decompress_tgz, "TMP", "item", hash_including(type: :file))
          subject.execute
        end

        context "with compression type set to zip" do
          before { argv << "-C" << "zip" }

          it "should test guest for decompression capability" do
            expect(guest).to receive(:capability?).with(:decompress_zip).and_return(true)
            subject.execute
          end

          it "should compress source using zip" do
            expect(subject).to receive(:compress_source_zip)
            subject.execute
          end

          it "should have guest decompress file using zip" do
            expect(guest).to receive(:capability).with(:decompress_zip, any_args)
            subject.execute
          end
        end
      end
    end
  end
end
