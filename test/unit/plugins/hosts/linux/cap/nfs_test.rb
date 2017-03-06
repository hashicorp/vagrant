require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/linux/cap/nfs"
require_relative "../../../../../../lib/vagrant/util"

describe VagrantPlugins::HostLinux::Cap::NFS do

  include_context "unit"

  let(:caps) do
    VagrantPlugins::HostLinux::Plugin
      .components
      .host_capabilities[:linux]
  end

  let(:data_dir){ Dir.mktmpdir("vagrant-nfs-test") }
  let(:env) do
    double(:env,
      data_dir: Pathname.new(data_dir),
      default_provider: "default-provider"
    )
  end
  let(:ui){ double(:ui) }
  let(:host){ double(:host) }
  let(:machine_id){ SecureRandom.uuid }

  before do
    allow(env).to receive(:lock).and_yield
  end

  after do
    FileUtils.rm_rf(data_dir)
  end

  describe ".nfs_export" do

    let(:cap){ caps.get(:nfs_export) }
    let(:check_result){ Vagrant::Util::Subprocess::Result.new(0, "", "") }
    let(:start_result){ Vagrant::Util::Subprocess::Result.new(0, "", "") }
    let(:exportfs_result){ Vagrant::Util::Subprocess::Result.new(0, "", "") }
    let(:export_folder_args) do
      [
        ["127.0.0.1"],
        {"tmp" => {:hostpath => "/tmp",
          :map_uid => :auto, :map_gid => :auto,
          :uuid => SecureRandom.uuid
        }}
      ]
    end

    before do
      allow(env).to receive(:host).and_return(host)
      allow(host).to receive(:capability).with(:nfs_check_command).and_return("/bin/true check")
      allow(host).to receive(:capability).with(:nfs_start_command).and_return("/bin/true start")
      allow(ui).to receive(:info)
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("/bin/true", "check").and_return(check_result)
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("sudo", "/bin/true", "start").and_return(start_result)
      # NOTE: `any_args` not working as expected here so just using `anything`s instead
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("sudo", "exportfs", anything, anything, anything).and_return(exportfs_result)
    end

    it "should check if nfsd is running" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("/bin/true", "check").and_return(check_result)
      cap.nfs_export(env, ui, machine_id, ["127.0.0.1"], "tmp" => {:hostpath => "/tmp"})
    end

    it "should export the defined folder" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "sudo", "exportfs", "-o", "#{described_class.const_get(:DEFAULT_MOUNT_OPTIONS).join(",")},anongid=auto," \
          "anonuid=auto,fsid=#{export_folder_args.last["tmp"][:uuid]}",
        "#{export_folder_args.first.first}:#{export_folder_args.last["tmp"][:hostpath]}"
      )
      cap.nfs_export(env, ui, machine_id, *export_folder_args)
    end

    it "should create an ID mapping file" do
      cap.nfs_export(env, ui, machine_id, *export_folder_args)
      idmap_path = cap.nfs_idmap_path(env)
      expect(File.exist?(idmap_path)).to be(true)
    end

    it "should create an entry for the synced folder in the mapping file" do
      cap.nfs_export(env, ui, machine_id, *export_folder_args)
      idmap_path = cap.nfs_idmap_path(env)
      idmap = JSON.parse(idmap_path.read)
      expect(idmap[env.default_provider][machine_id]).to be_a(Array)
    end

    it "should store the machine address in the mapping file entry" do
      cap.nfs_export(env, ui, machine_id, *export_folder_args)
      idmap_path = cap.nfs_idmap_path(env)
      idmap = JSON.parse(idmap_path.read)
      expect(idmap[env.default_provider][machine_id].first["address"]).to eql("127.0.0.1")
    end

    it "should store the host folder path in the mapping file entry" do
      cap.nfs_export(env, ui, machine_id, *export_folder_args)
      idmap_path = cap.nfs_idmap_path(env)
      idmap = JSON.parse(idmap_path.read)
      expect(idmap[env.default_provider][machine_id].first["paths"].first).to eql("/tmp")
    end

    context "when NFSD is not running" do
      let(:check_result){ Vagrant::Util::Subprocess::Result.new(1, "", "") }

      it "should start the NFS server" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("sudo", "/bin/true", "start").and_return(start_result)
        cap.nfs_export(env, ui, machine_id, ["127.0.0.1"], "tmp" => {:hostpath => "/tmp"})
      end

      context "when NFSD fails to start" do
        let(:start_result){ Vagrant::Util::Subprocess::Result.new(1, "", "") }

        it "should raise an error" do
          expect do
            cap.nfs_export(env, ui, machine_id, *export_folder_args)
          end.to raise_error(Vagrant::Errors::NFSDStartFailure)
        end
      end
    end

    context "when exportfs fails to setup share" do
      let(:exportfs_result){ Vagrant::Util::Subprocess::Result.new(1, "", "") }

      it "should raise an error" do
        expect do
          cap.nfs_export(env, ui, machine_id, *export_folder_args)
        end.to raise_error(Vagrant::Errors::NFSExportfsExportFailed)
      end
    end
  end

  describe ".nfs_installed" do
    let(:cap){ caps.get(:nfs_installed) }

    context "when NFS is installed" do
      before{ expect(File).to receive(:read).with("/proc/filesystems").and_return("\text3\nnodev\tnfsd\n") }

      it "should return true" do
        expect(cap.nfs_installed(env)).to be(true)
      end
    end

    context "when NFS is not installed" do
      before{ expect(File).to receive(:read).with("/proc/filesystems").and_return("\text3\nnodev\tcifs\n") }

      it "should return false" do
        expect(cap.nfs_installed(env)).to be(false)
      end
    end
  end

  describe ".nfs_prune" do

    let(:cap){ caps.get(:nfs_prune) }

    before do
      allow(ui).to receive(:info)
    end

    it "should remove entries no longer valid" do

    end
  end

  describe ".nfs_cleanup" do
    let(:ip){ "127.0.0.1" }
    let(:host){ "/tmp" }
    let(:prune_result){ Vagrant::Util::Subprocess::Result.new(0, "", "") }

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with(any_args).
        and_return(prune_result)
    end

    it "should execute command to remove share" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("sudo", "exportfs", "-u", "#{ip}:#{host}")
      described_class.nfs_cleanup(ip, host)
    end

    context "when share removal command fails" do
      let(:prune_result){ Vagrant::Util::Subprocess::Result.new(1, "", "") }

      it "should raise an error" do
        expect{ described_class.nfs_cleanup(ip, host) }.to raise_error(Vagrant::Errors::NFSExportfsPruneFailed)
      end
    end
  end

  describe ".nfs_opts_setup" do
    let(:folders) do
      {"tmp" => {:hostpath => "/tmp",
        :map_uid => :auto, :map_gid => :auto,
        :uuid => SecureRandom.uuid
      }}
    end

    it "should add linux specific nfs options" do
      expect(folders["tmp"][:linux__nfs_options]).to be_nil
      described_class.nfs_opts_setup(folders)
      expect(folders["tmp"][:linux__nfs_options]).not_to be_nil
    end

    it "should add anongid" do
      described_class.nfs_opts_setup(folders)
      expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("anongid=")}).to be(true)
    end

    it "should add anonuid" do
      described_class.nfs_opts_setup(folders)
      expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("anonuid=")}).to be(true)
    end

    it "should add fsid" do
      described_class.nfs_opts_setup(folders)
      expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("fsid=")}).to be(true)
    end

    context "with anongid linux option predefined" do
      before{ folders["tmp"][:linux__nfs_options] = ["anongid=CUSTOM"] }

      it "should not add anongid" do
        described_class.nfs_opts_setup(folders)
        expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("anongid=CUSTOM")}).to be(true)
        expect(folders["tmp"][:linux__nfs_options].find_all{|o| o.include?("anongid")}.size).to eql(1)
      end
    end

    context "with anonuid linux option predefined" do
      before{ folders["tmp"][:linux__nfs_options] = ["anonuid=CUSTOM"] }

      it "should not add anonuid" do
        described_class.nfs_opts_setup(folders)
        expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("anonuid=CUSTOM")}).to be(true)
        expect(folders["tmp"][:linux__nfs_options].find_all{|o| o.include?("anonuid")}.size).to eql(1)
      end
    end

    context "with fsid linux option predefined" do
      before{ folders["tmp"][:linux__nfs_options] = ["fsid=CUSTOM"] }

      it "should not add fsid" do
        described_class.nfs_opts_setup(folders)
        expect(folders["tmp"][:linux__nfs_options].any?{|o| o.include?("fsid=CUSTOM")}).to be(true)
        expect(folders["tmp"][:linux__nfs_options].find_all{|o| o.include?("fsid")}.size).to eql(1)
      end
    end
  end

  describe ".nfs_running" do
    let(:check_command){ "/bin/true check" }
    before do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("/bin/true", "check").and_return(check_result)
    end

    context "when nfs is running" do
      let(:check_result){ Vagrant::Util::Subprocess::Result.new(0, "", "") }

      it "should return true" do
        expect(described_class.nfs_running?(check_command)).to be(true)
      end
    end

    context "when nfs is not running" do
      let(:check_result){ Vagrant::Util::Subprocess::Result.new(1, "", "") }

      it "should return false" do
        expect(described_class.nfs_running?(check_command)).to be(false)
      end
    end
  end

  describe ".nfs_current_exports" do
    let(:list_command){ ["sudo", "exportfs", "-v"] }
    let(:list_result){ Vagrant::Util::Subprocess::Result.new(0, list_stdout, "") }
    let(:list_stdout){ "" }

    before do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(*list_command).and_return(list_result)
    end

    it "should return an array" do
      expect(described_class.nfs_current_exports).to be_a(Array)
    end

    it "should return an empty array" do
      expect(described_class.nfs_current_exports).to be_empty
    end

    context "when listing command fails" do
      let(:list_result){ Vagrant::Util::Subprocess::Result.new(1, list_stdout, "") }

      it "should raise an error" do
        expect{ described_class.nfs_current_exports }.to raise_error(Vagrant::Errors::NFSExportfsListFailed)
      end
    end

    context "when listing command returns short paths" do
      let(:list_stdout){ "/short    \t127.0.0.1(opts=val)\n/short2    \t127.0.1.1(opts=val)\n" }

      it "should return two results" do
        expect(described_class.nfs_current_exports.size).to be(2)
      end

      it "should extract export information" do
        result = described_class.nfs_current_exports
        expect(result.first[:hostpath]).to eq("/short")
        expect(result.first[:ip]).to eq("127.0.0.1")
        expect(result.first[:linux__nfs_options]).to eq("opts=val")
      end
    end

    context "with command result in unknown format" do
      let(:list_stdout){ "junk response" }

      it "should return an empty result" do
        expect(described_class.nfs_current_exports).to be_empty
      end
    end
  end

  describe ".nfs_idmap_path" do

    it "should return Pathname to mapping file" do
      expect(described_class.nfs_idmap_path(env)).to be_a(Pathname)
    end

    it "should create required directories to path" do
      expect(File.directory?(File.dirname(described_class.nfs_idmap_path(env)))).to be(true)
    end
  end

  describe ".record_nfs_idmap" do

    let(:mount_info){ [{"address" =>  "127.0.0.1", "paths" => ["/tmp"]}]}

    it "should store data to mapping file" do
      expect(File.file?(described_class.nfs_idmap_path(env))).to be(false)
      described_class.record_nfs_idmap(env, machine_id, mount_info)
      expect(File.file?(described_class.nfs_idmap_path(env))).to be(true)
    end

    it "should store mount information within provider" do
      described_class.record_nfs_idmap(env, machine_id, mount_info)
      data = JSON.parse(described_class.nfs_idmap_path(env).read)
      expect(data[env.default_provider]).to eq(machine_id => mount_info)
    end

    context "when data currently exists within mapping file" do
      let(:existing_data) do
        {"other-provider" => {"other-id" => {"address" => "127.0.0.1", "paths" => ["/a/path"]}},
          env.default_provider.to_s => {"existing-id" => [{"address" => "127.0.1.1", "paths" => ["/tmp"]}]}}
      end
      before{ described_class.nfs_idmap_path(env).write(JSON.dump(existing_data)) }

      it "should merge data into existing provider data" do
        described_class.record_nfs_idmap(env, machine_id, mount_info)
        data = JSON.parse(described_class.nfs_idmap_path(env).read)
        expect(data[env.default_provider.to_s]["other-id"]).to eq(existing_data[env.default_provider.to_s]["other-id"])
        expect(data[env.default_provider.to_s][machine_id]).to eq(mount_info)
      end

      it "should not remove other provider data" do
        described_class.record_nfs_idmap(env, machine_id, mount_info)
        data = JSON.parse(described_class.nfs_idmap_path(env).read)
        expect(data["other-provider"]).to eq(existing_data["other-provider"])
      end
    end
  end

  describe ".clean_nfs_idmap" do
    let(:existing_data) do
      {"other-provider" => {"other-id" => {"address" => "127.0.0.1", "paths" => ["/a/path"]}},
        env.default_provider.to_s => {
          "existing-id" => [{"address" => "127.0.1.1", "paths" => ["/tmp"]}],
          machine_id => [{"address" => "127.1.1.1", "paths" => ["/var"]}]
        }}
    end
    before{ described_class.nfs_idmap_path(env).write(JSON.dump(existing_data)) }

    it "should remove requested IDs from within current provider" do
      described_class.clean_nfs_idmap(env, [machine_id])
      data = JSON.parse(described_class.nfs_idmap_path(env).read)
      expect(data[env.default_provider.to_s][machine_id]).to be_nil
    end

    it "should not remove unrequested IDs from within current provider" do
      described_class.clean_nfs_idmap(env, [machine_id])
      data = JSON.parse(described_class.nfs_idmap_path(env).read)
      expect(data[env.default_provider.to_s]["existing-id"]).not_to be_nil
    end

    it "should not modify non-current provider" do
      described_class.clean_nfs_idmap(env, [machine_id])
      data = JSON.parse(described_class.nfs_idmap_path(env).read)
      expect(data["other-provider"]).to eq(existing_data["other-provider"])
    end
  end

  describe ".load_nfs_idmap" do

    it "should return an empty Hash when mapping file does not exist" do
      expect(described_class.load_nfs_idmap(env)).to eq({})
    end

    context "when mapping file contains content" do
      let(:existing_data) do
        {"other-provider" => {"other-id" => {"address" => "127.0.0.1", "paths" => ["/a/path"]}},
          env.default_provider.to_s => {
            "existing-id" => [{"address" => "127.0.1.1", "paths" => ["/tmp"]}],
            machine_id => [{"address" => "127.1.1.1", "paths" => ["/var"]}]
          }}
      end
      before{ described_class.nfs_idmap_path(env).write(JSON.dump(existing_data)) }

      it "should load the content from the file" do
        expect(described_class.load_nfs_idmap(env)).to eq(existing_data)
      end
    end
  end
end
