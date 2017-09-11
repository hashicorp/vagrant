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

  let(:tmp_exports_path) do
    @tmp_exports ||= temporary_file
  end
  let(:exports_path){ VagrantPlugins::HostLinux::Cap::NFS::NFS_EXPORTS_PATH }
  let(:env){ double(:env) }
  let(:ui){ double(:ui) }
  let(:host){ double(:host) }

  before do
    @original_exports_path = VagrantPlugins::HostLinux::Cap::NFS::NFS_EXPORTS_PATH
    VagrantPlugins::HostLinux::Cap::NFS.send(:remove_const, :NFS_EXPORTS_PATH)
    VagrantPlugins::HostLinux::Cap::NFS.const_set(:NFS_EXPORTS_PATH, tmp_exports_path.to_s)
  end

  after do
    VagrantPlugins::HostLinux::Cap::NFS.send(:remove_const, :NFS_EXPORTS_PATH)
    VagrantPlugins::HostLinux::Cap::NFS.const_set(:NFS_EXPORTS_PATH, @original_exports_path)
    File.unlink(tmp_exports_path.to_s) if File.exist?(tmp_exports_path.to_s)
    @tmp_exports = nil
  end

  describe ".nfs_check_command" do
    let(:cap){ caps.get(:nfs_check_command) }

    context "without systemd" do
      before{ expect(Vagrant::Util::Platform).to receive(:systemd?).and_return(false) }

      it "should use init.d script" do
        expect(cap.nfs_check_command(env)).to include("init.d")
      end
    end
    context "with systemd" do
      before{ expect(Vagrant::Util::Platform).to receive(:systemd?).and_return(true) }

      it "should use systemctl" do
        expect(cap.nfs_check_command(env)).to include("systemctl")
      end
    end
  end

  describe ".nfs_start_command" do
    let(:cap){ caps.get(:nfs_start_command) }

    context "without systemd" do
      before{ expect(Vagrant::Util::Platform).to receive(:systemd?).and_return(false) }

      it "should use init.d script" do
        expect(cap.nfs_start_command(env)).to include("init.d")
      end
    end
    context "with systemd" do
      before{ expect(Vagrant::Util::Platform).to receive(:systemd?).and_return(true) }

      it "should use systemctl" do
        expect(cap.nfs_start_command(env)).to include("systemctl")
      end
    end
  end

  describe ".nfs_export" do

    let(:cap){ caps.get(:nfs_export) }

    before do
      allow(env).to receive(:host).and_return(host)
      allow(host).to receive(:capability).with(:nfs_apply_command).and_return("/bin/true")
      allow(host).to receive(:capability).with(:nfs_check_command).and_return("/bin/true")
      allow(host).to receive(:capability).with(:nfs_start_command).and_return("/bin/true")
      allow(ui).to receive(:info)
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_call_original
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("sudo", "/bin/true").and_return(double(:result, exit_code: 0))
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("/bin/true").and_return(double(:result, exit_code: 0))
    end

    it "should export new entries" do
      cap.nfs_export(env, ui, SecureRandom.uuid, ["127.0.0.1"], "tmp" => {:hostpath => "/tmp"})
      exports_content = File.read(exports_path)
      expect(exports_content).to match(/\/tmp.*127\.0\.0\.1/)
    end

    it "should not remove existing entries" do
      File.write(exports_path, "/custom/directory hostname1(rw,sync,no_subtree_check)")
      cap.nfs_export(env, ui, SecureRandom.uuid, ["127.0.0.1"], "tmp" => {:hostpath => "/tmp"})
      exports_content = File.read(exports_path)
      expect(exports_content).to match(/\/tmp.*127\.0\.0\.1/)
      expect(exports_content).to match(/\/custom\/directory.*hostname1/)
    end

    it "should remove entries no longer valid" do
      valid_id = SecureRandom.uuid
      other_id = SecureRandom.uuid
      content =<<-EOH
# VAGRANT-BEGIN: #{Process.uid} #{other_id}
"/tmp" 127.0.0.1(rw,no_subtree_check,all_squash,anonuid=,anongid=,fsid=)
# VAGRANT-END: #{Process.uid} #{other_id}
# VAGRANT-BEGIN: #{Process.uid} #{valid_id}
"/var" 127.0.0.1(rw,no_subtree_check,all_squash,anonuid=,anongid=,fsid=)
# VAGRANT-END: #{Process.uid} #{valid_id}
EOH
      File.write(exports_path, content)
      cap.nfs_export(env, ui, valid_id, ["127.0.0.1"], "home" => {:hostpath => "/home"})
      exports_content = File.read(exports_path)
      expect(exports_content).to include("/home")
      expect(exports_content).to include("/tmp")
      expect(exports_content).not_to include("/var")
    end

    it "throws an exception with at least 2 different nfs options" do
      folders = {"/vagrant"=>
                 {:hostpath=>"/home/vagrant",
                  :linux__nfs_options=>["rw","all_squash"]},
                 "/var/www/project"=>
                 {:hostpath=>"/home/vagrant",
                  :linux__nfs_options=>["rw","sync"]}}

      expect { cap.nfs_export(env, ui, SecureRandom.uuid, ["127.0.0.1"], folders) }.
        to raise_error Vagrant::Errors::NFSDupePerms
    end

    it "writes only 1 hostpath for multiple exports" do
      folders = {"/vagrant"=>
                 {:hostpath=>"/home/vagrant",
                  :linux__nfs_options=>["rw","all_squash"]},
                 "/var/www/otherproject"=>
                 {:hostpath=>"/newhome/otherproject",
                  :linux__nfs_options=>["rw","all_squash"]},
                 "/var/www/project"=>
                 {:hostpath=>"/home/vagrant",
                  :linux__nfs_options=>["rw","all_squash"]}}
      valid_id = SecureRandom.uuid
      content =<<-EOH
\n# VAGRANT-BEGIN: #{Process.uid} #{valid_id}
"/home/vagrant" 127.0.0.1(rw,all_squash,anonuid=,anongid=,fsid=)
"/newhome/otherproject" 127.0.0.1(rw,all_squash,anonuid=,anongid=,fsid=)
# VAGRANT-END: #{Process.uid} #{valid_id}
EOH

      cap.nfs_export(env, ui, valid_id, ["127.0.0.1"], folders)
      exports_content = File.read(exports_path)
      expect(exports_content).to eq(content)
    end

  end

  describe ".nfs_prune" do

    let(:cap){ caps.get(:nfs_prune) }

    before do
      allow(ui).to receive(:info)
    end

    it "should remove entries no longer valid" do
      invalid_id = SecureRandom.uuid
      valid_id = SecureRandom.uuid
      content =<<-EOH
# VAGRANT-BEGIN: #{Process.uid} #{invalid_id}
"/tmp" 127.0.0.1(rw,no_subtree_check,all_squash,anonuid=,anongid=,fsid=)
# VAGRANT-END: #{Process.uid} #{invalid_id}
# VAGRANT-BEGIN: #{Process.uid} #{valid_id}
"/var" 127.0.0.1(rw,no_subtree_check,all_squash,anonuid=,anongid=,fsid=)
# VAGRANT-END: #{Process.uid} #{valid_id}
EOH
      File.write(exports_path, content)
      cap.nfs_prune(env, ui, [valid_id])
      exports_content = File.read(exports_path)
      expect(exports_content).to include(valid_id)
      expect(exports_content).not_to include(invalid_id)
      expect(exports_content).to include("/var")
      expect(exports_content).not_to include("/tmp")
    end
  end

  describe ".nfs_write_exports" do

    before do
      File.write(tmp_exports_path, "original content")
    end

    it "should write updated contents to file" do
      described_class.nfs_write_exports("new content")
      exports_content = File.read(exports_path)
      expect(exports_content).to include("new content")
      expect(exports_content).not_to include("original content")
    end

    it "should only update contents if different" do
      original_stat = File.stat(exports_path)
      described_class.nfs_write_exports("original content")
      updated_stat = File.stat(exports_path)
      expect(original_stat).to eq(updated_stat)
    end

    it "should retain existing file permissions" do
      File.chmod(0600, exports_path)
      original_stat = File.stat(exports_path)
      described_class.nfs_write_exports("original content")
      updated_stat = File.stat(exports_path)
      expect(original_stat.mode).to eq(updated_stat.mode)
    end

    it "should raise exception when failing to move new exports file" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(
        Vagrant::Util::Subprocess::Result.new(1, "Failed to move file", "")
      )
      expect{ described_class.nfs_write_exports("new content") }.to raise_error(Vagrant::Errors::NFSExportsFailed)
    end

    it "should retain existing file owner and group IDs" do
      pending("investigate using a simulated FS to test")
      test_with_simulated_fs
    end

    it "should raise custom exception when chown fails" do
      pending("investigate using a simulated FS to test")
      test_with_simulated_fs
    end
  end
end
