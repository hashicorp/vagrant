require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::CloudInitSetup do
  let(:app) { lambda { |env| } }
  let(:vm) { double("vm", disk: disk, disks: disks) }
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

  let(:ui)  { double("ui", info: true, warn: true) }

  let(:cfg) { double("cfg", type: :user_data, content_type: "text/cloud-config",
                     path: "my/path", inline: nil) }
  let(:cfg_inline) { double("cfg", type: :user_data, content_type: "text/cloud-config",
                     inline: "data: true", path: nil) }
  let(:cloud_init_configs) { [cfg, cfg_inline] }

  let(:text_cfgs) { [MIME::Text.new("data: true", "cloud-config"),
                     MIME::Text.new("data: false", "cloud-config") ] }

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
      expect(subject).not_to receive(:attack_disk_config)

      subject.call(env)
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
      allow(File).to receive(:read).and_return(cfg_text)

      expect(MIME::Text).to receive(:new).with(cfg_text, "cloud-config")
      subject.read_text_cfg(machine, cfg)
    end

    it "takes a text cfg inline string and saves it as a MIME text message" do
      expect(MIME::Text).to receive(:new).with("data: true", "cloud-config")
      subject.read_text_cfg(machine, cfg_inline)
    end
  end

  describe "#generate_cfg_msg" do
    it "creates a miltipart mixed message of combined configs" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      expect(message).to be_a(MIME::Multipart::Mixed)
    end

    it "sets a MIME-Version header" do
      message = subject.generate_cfg_msg(machine, text_cfgs)
      expect(message.headers.get("MIME-Version")).to eq("1.0")
    end
  end

  describe "#write_cfg_iso" do
    let(:iso_path) { Pathname.new("fake/iso/path") }
    let(:source_dir) { Pathname.new("fake/source/path") }
    let(:meta_data_file) { double("meta_data_file") }

    before do
      allow(meta_data_file).to receive(:write).and_return(true)
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
  end

  describe "#attach_disk_config" do
    let(:iso_path) { Pathname.new("fake/iso/path") }

    it "creates a new disk config based on the iso_path" do
      expect(vm.disks).to receive(:each)
      subject.attach_disk_config(machine, env, iso_path)
    end
  end
end
