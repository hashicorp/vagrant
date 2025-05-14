# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../../../base", __FILE__)
require "vagrant/util/mime"

describe Vagrant::Action::Builtin::CloudInitSetup do
  let(:app) { lambda { |env| } }
  let(:vm) { double("vm", disk: disk, disks: disks, cloud_init_first_boot_only: first_boot_only) }
  let(:first_boot_only) { true }
  let(:disk) { double("disk") }
  let(:disks) { double("disk") }
  let(:config) { double("config", vm: vm) }
  let(:provider) { double("provider") }
  let(:machine) { double("machine", config: config, provider: provider, name: "machine",
                         provider_name: "provider", data_dir: Pathname.new("/fake/dir"),
                         ui: ui, env: machine_env, id: "123-456-789") }
  let(:host) { double("host") }
  let(:machine_env) { double("machine_env", root_path: "root", host: host) }
  let(:env) { { ui: ui, machine: machine, env: machine_env} }

  let(:ui)  { Vagrant::UI::Silent.new }

  let(:cfg) { double("cfg", type: :user_data, content_type: "text/cloud-config",
                     content_disposition_filename: nil, path: "my/path",
                     inline: nil) }
  let(:cfg_inline) { double("cfg", type: :user_data, content_type: "text/cloud-config",
                            content_disposition_filename: nil, inline: "data: true",
                            path: nil) }
  let(:cfg_with_content_disposition_filename_inline) {
    double("cfg", type: :user_data, content_type: "text/x-shellscript",
           content_disposition_filename: "test.ps1",
           inline: "#ps1_sysnative\n", path: nil) }
  let(:cloud_init_configs) { [cfg, cfg_inline] }

  let(:text_cfgs) { [Vagrant::Util::Mime::Entity.new("data: true", "text/cloud-config"),
                     Vagrant::Util::Mime::Entity.new("data: false", "text/cloud-config") ] }

  let(:meta_data) { { "instance-id" => "i-123456789" } }


  let(:subject) { described_class.new(app, env) }

  describe "#call" do
    it "calls setup_user_data if cloud_init config present" do
      allow(vm).to receive(:cloud_init_configs).and_return(cloud_init_configs)

      expect(app).to receive(:call).with(env).ordered

      expect(subject).to receive(:setup_user_data).and_return(true)
      expect(subject).to receive(:write_cfg_iso).and_return(true)

      subject.call(env)
    end

    it "continues on if no cloud_init config present" do
      allow(vm).to receive(:cloud_init_configs).and_return([])

      expect(app).to receive(:call).with(env).ordered

      expect(subject).not_to receive(:setup_user_data)
      expect(subject).not_to receive(:write_cfg_iso)
      expect(subject).not_to receive(:attach_disk_config)

      subject.call(env)
    end

    context "sentinel file" do
      let(:sentinel) { double("sentinel") }
      let(:sentinel_exists) { false }
      let(:sentinel_contents) { "" }

      before do
        allow(machine).to receive_message_chain(:data_dir, :join).with("action_cloud_init").and_return(sentinel)
        allow(sentinel).to receive(:file?).and_return(sentinel_exists)
        allow(sentinel).to receive(:read).and_return(sentinel_contents)
        allow(sentinel).to receive(:unlink)

        allow(vm).to receive(:cloud_init_configs).and_return(cloud_init_configs)
        allow(subject).to receive(:setup_user_data)
        allow(subject).to receive(:write_cfg_iso)
      end

      context "when file exists" do
        let(:sentinel_exists) { true }

        context "when file contains machine id" do
          let(:sentinel_contents) { machine.id.to_s }

          it "should not write iso configuration" do
            expect(subject).not_to receive(:write_cfg_iso)

            subject.call(env)
          end

          context "when configuration enables on all boots" do
            let(:first_boot_only) { false }

            it "should write the iso configuration" do
              expect(subject).to receive(:write_cfg_iso)
              subject.call(env)
            end

            it "should remove sentinel file" do
              expect(sentinel).to receive(:unlink)
              subject.call(env)
            end
          end
        end

        context "when file does not contain machine id" do
          let(:sentinel_contents) { "unknown-id" }

          it "should write iso configuration" do
            expect(subject).to receive(:write_cfg_iso)
            subject.call(env)
          end

          it "should remove sentinel file" do
            expect(sentinel).to receive(:unlink)
            subject.call(env)
          end
        end
      end
    end
  end

  describe "#setup_user_data" do
    it "builds a MIME message and prepares a disc to be attached" do
      expect(subject).to receive(:read_text_cfg).twice

      expect(subject).to receive(:generate_cfg_msg)

      subject.setup_user_data(machine, env, cloud_init_configs)
    end
  end

  describe "#read_text_cfg" do
    let(:cfg_text) { "config: true" }

    it "takes a text cfg path and saves it as a MIME text message" do
      mime_text_part = double("mime_text_part")
      expect(mime_text_part).not_to receive(:disposition=)
      allow(File).to receive(:read).and_return(cfg_text)
      expect(Vagrant::Util::Mime::Entity).to receive(:new).with(cfg_text, "text/cloud-config").and_return(mime_text_part)
      subject.read_text_cfg(machine, cfg)
    end

    it "takes a text cfg inline string and saves it as a MIME text message" do
      mime_text_part = double("mime_text_part")
      expect(mime_text_part).not_to receive(:disposition=)
      expect(Vagrant::Util::Mime::Entity).to receive(:new).with("data: true", "text/cloud-config").and_return(mime_text_part)
      subject.read_text_cfg(machine, cfg_inline)
    end

    it "takes a text cfg inline string with content_disposition_filename and saves it as a MIME text message" do
      mime_text_part = double("mime_text_part")
      expect(mime_text_part).to receive(:disposition=).with("attachment; filename=\"test.ps1\"")
      expect(Vagrant::Util::Mime::Entity).to receive(:new).with("#ps1_sysnative\n", "text/x-shellscript").and_return(mime_text_part)
      subject.read_text_cfg(machine, cfg_with_content_disposition_filename_inline)
    end
  end

  describe "#generate_cfg_msg" do
    it "creates a miltipart mixed message of combined configs" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      expect(message).to be_a(Vagrant::Util::Mime::Multipart)
    end

    it "sets a MIME-Version header" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      expect(message.headers["MIME-Version"]).to eq("1.0")
    end
  end

  describe "#write_cfg_iso" do
    let(:iso_path) { Pathname.new("fake/iso/path") }
    let(:source_dir) { Pathname.new("fake/source/path") }
    let(:meta_data_file) { double("meta_data_file") }
    let(:sentinel) { double("sentinel") }
    let(:sentinel_exists) { false }
    let(:file_checksum) { double("file_checksum", checksum: checksum) }
    let(:checksum) { "DUMMY-CHECKSUM-VALUE" }

    before do
      allow(meta_data_file).to receive(:write).and_return(true)
      allow(machine).to receive_message_chain(:data_dir, :join).with("action_cloud_init_iso").and_return(sentinel)
      allow(sentinel).to receive(:file?).and_return(sentinel_exists)
      allow(sentinel).to receive(:write)
      allow(Vagrant::Util::FileChecksum).to receive(:new).with(iso_path, :sha256).and_return(file_checksum)
      allow(Vagrant::Util::FileChecksum).to receive(:new).with(iso_path.to_s, :sha256).and_return(file_checksum)
    end

    it "raises an error if the host capability is not supported" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      allow(host).to receive(:capability?).with(:create_iso).and_return(false)

      expect{subject.write_cfg_iso(machine, env, message, {})}.to raise_error(Vagrant::Errors::CreateIsoHostCapNotFound)
    end

    it "creates a temp dir with the cloud_init config and generates an iso" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      allow(host).to receive(:capability?).with(:create_iso).and_return(true)
      allow(Dir).to receive(:mktmpdir).and_return(source_dir)
      expect(File).to receive(:open).with("#{source_dir}/user-data", 'w').and_return(true)
      expect(File).to receive(:open).with("#{source_dir}/meta-data", 'w').and_yield(meta_data_file)
      expect(FileUtils).to receive(:remove_entry).with(source_dir).and_return(true)
      allow(host).to receive(:capability).with(:create_iso, source_dir, volume_id: "cidata").and_return(iso_path)
      expect(vm.disks).to receive(:each)
      expect(meta_data).to receive(:to_yaml)


      subject.write_cfg_iso(machine, env, message, meta_data)
    end

    context "sentinel file" do
      let(:user_data) { double("user_data") }
      let(:sentinel_contents) { "" }

      before do
        allow(sentinel).to receive(:read).and_return(sentinel_contents)
        allow(sentinel).to receive(:unlink)

        allow(host).to receive(:capability?).with(:create_iso).and_return(true)
        allow(Dir).to receive(:mktmpdir).and_return(source_dir)
        allow(File).to receive(:open).with("#{source_dir}/user-data", 'w').and_return(true)
        allow(File).to receive(:open).with("#{source_dir}/meta-data", 'w').and_yield(meta_data_file)
        allow(FileUtils).to receive(:remove_entry).with(source_dir).and_return(true)
        allow(FileUtils).to receive(:remove_entry).with(source_dir).and_return(true)
        allow(host).to receive(:capability).with(:create_iso, source_dir, volume_id: "cidata").and_return(iso_path)
        allow(subject).to receive(:attach_disk_config)
      end

      context "when file exists" do
        let(:sentinel_exists) { true }

        context "when file contents is iso path" do
          let(:sentinel_contents) { "#{checksum}:#{iso_path}" }

          context "when file contents path exists" do
            before do
              expect(File).to receive(:exist?).with(iso_path.to_s).and_return(true)
            end

            it "should not create iso" do
              expect(host).not_to receive(:capability)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should attach with the iso path" do
              expect(subject).to receive(:attach_disk_config).with(machine, env, iso_path.to_path)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should not write the sentinel file" do
              expect(sentinel).not_to receive(:write)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end
          end

          context "when file contents path does not exist" do
            before do
              expect(File).to receive(:exist?).with(iso_path.to_s).and_return(false)
            end

            it "should create iso" do
              expect(host).to receive(:capability).with(:create_iso, source_dir, volume_id: "cidata").and_return(iso_path)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should remove the sentinel file" do
              expect(sentinel).to receive(:unlink)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should write the sentinel file" do
              expect(sentinel).to receive(:write).with("#{checksum}:#{iso_path}")
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end
          end

          context "when file contents checksum does not match existing file checksum" do
            let(:sentinel_contents) { "BAD-CHECKSUM-VALUE:#{iso_path}" }

            it "should create iso" do
              expect(host).to receive(:capability).with(:create_iso, source_dir, volume_id: "cidata").and_return(iso_path)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should remove the sentinel file" do
              expect(sentinel).to receive(:unlink)
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end

            it "should write the sentinel file" do
              expect(sentinel).to receive(:write).with("#{checksum}:#{iso_path}")
              subject.write_cfg_iso(machine, env, user_data, meta_data)
            end
          end
        end
      end

      context "when file does not exist" do
        let(:sentinel_exists) { false }

        it "should create iso" do
          expect(host).to receive(:capability).with(:create_iso, source_dir, volume_id: "cidata").and_return(iso_path)
          subject.write_cfg_iso(machine, env, user_data, meta_data)
        end

        it "should write the sentinel file" do
          expect(sentinel).to receive(:write).with("#{checksum}:#{iso_path}")
          subject.write_cfg_iso(machine, env, user_data, meta_data)
        end
      end
    end
  end

  describe "#attach_disk_config" do
    let(:iso_path) { Pathname.new("fake/iso/path") }

    it "creates a new disk config based on the iso_path" do
      expect(vm.disks).to receive(:each)
      subject.attach_disk_config(machine, env, iso_path)
    end
  end
end
