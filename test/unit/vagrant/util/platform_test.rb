# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"

describe Vagrant::Util::Platform do
  include_context "unit"
  before(:all) { described_class.reset! }
  after { described_class.reset! }
  subject { described_class }

  describe "#cygwin_path" do
    let(:path) { "C:\\msys2\\home\\vagrant" }
    let(:updated_path) { "/home/vagrant" }
    let(:subprocess_result) do
      double("subprocess_result").tap do |result|
        allow(result).to receive(:exit_code).and_return(0)
        allow(result).to receive(:stdout).and_return(updated_path)
      end
    end

    it "takes a windows path and returns a formatted path" do
      allow(Vagrant::Util::Which).to receive(:which).and_return("C:/msys2/cygpath")
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)

      expect(Vagrant::Util::Subprocess).to receive(:execute).with("C:\\msys2\\cygpath", "-u", "-a", "C:\\msys2\\home\\vagrant")

      expect(subject.cygwin_path(path)).to eq("/home/vagrant")
    end
  end

  describe "#msys_path" do
    let(:updated_path) { "/home/vagrant" }
    let(:subprocess_result) do
      double("subprocess_result").tap do |result|
        allow(result).to receive(:exit_code).and_return(0)
        allow(result).to receive(:stdout).and_return(updated_path)
      end
    end
    let(:old_path) { "/old/path/bin:/usr/local/bin:/usr/bin" }

    it "takes a windows path and returns a formatted path" do
      path = ENV["PATH"]
      allow(Vagrant::Util::Which).to receive(:which).and_return("C:/msys2/cygpath")
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
      allow(ENV).to receive(:[]).with("PATH").and_return(path)
      allow(ENV).to receive(:[]).with("VAGRANT_OLD_ENV_PATH").and_return(old_path)

      expect(Vagrant::Util::Subprocess).to receive(:execute).with("C:\\msys2\\cygpath", "-u", "-a", path)

      expect(subject.msys_path(path)).to eq("/home/vagrant")
      expect(ENV["PATH"]).to eq(path)
    end
  end

  describe "#cygwin?" do
    before do
      allow(subject).to receive(:platform).and_return("test")
    end

    around do |example|
      with_temp_env(VAGRANT_DETECTED_OS: "nope", PATH: "") do
        example.run
      end
    end

    it "returns true if VAGRANT_DETECTED_OS includes cygwin" do
      with_temp_env(VAGRANT_DETECTED_OS: "cygwin") do
        expect(subject).to be_cygwin
      end
    end

    it "returns true if OSTYPE includes cygwin" do
      with_temp_env(OSTYPE: "cygwin") do
        expect(subject).to be_cygwin
      end
    end

    it "returns true if platform has cygwin" do
      allow(subject).to receive(:platform).and_return("cygwin")
      expect(subject).to be_cygwin
    end

    it "returns false if the PATH contains cygwin" do
      with_temp_env(PATH: "C:/cygwin") do
        expect(subject).to_not be_cygwin
      end
    end

    it "returns false if nothing is available" do
      expect(subject).to_not be_cygwin
    end
  end

  describe "#msys?" do
    before do
      allow(subject).to receive(:platform).and_return("test")
    end

    around do |example|
      with_temp_env(VAGRANT_DETECTED_OS: "nope", PATH: "") do
        example.run
      end
    end

    it "returns true if VAGRANT_DETECTED_OS includes msys" do
      with_temp_env(VAGRANT_DETECTED_OS: "msys") do
        expect(subject).to be_msys
      end
    end

    it "returns true if OSTYPE includes msys" do
      with_temp_env(OSTYPE: "msys") do
        expect(subject).to be_msys
      end
    end

    it "returns true if platform has msys" do
      allow(subject).to receive(:platform).and_return("msys")
      expect(subject).to be_msys
    end

    it "returns false if the PATH contains msys" do
      with_temp_env(PATH: "C:/msys") do
        expect(subject).to_not be_msys
      end
    end

    it "returns false if nothing is available" do
      expect(subject).to_not be_msys
    end
  end

  describe "#fs_real_path" do
    it "fixes drive letters on Windows", :windows do
      expect(described_class.fs_real_path("c:/foo").to_s).to eql("C:/foo")
    end

    it "gracefully handles invalid input string errors" do
      bad_string = double("bad_string")
      allow(bad_string).to receive(:to_s).and_raise(ArgumentError)
      allow_any_instance_of(String).to receive(:encode).with("filesystem").and_return(bad_string)
      allow(subject).to receive(:fs_case_sensitive?).and_return(false)

      expect(described_class.fs_real_path("/dev/null").to_s).to eql("/dev/null")
    end
  end

  describe "#windows_unc_path" do
    it "correctly converts a path" do
      expect(described_class.windows_unc_path("c:/foo").to_s).to eql("\\\\?\\c:\\foo")
    end

    context "when given a UNC path" do
      let(:unc_path){ "\\\\srvname\\path" }

      it "should not modify the path" do
        expect(described_class.windows_unc_path(unc_path).to_s).to eql(unc_path)
      end
    end
  end

  describe ".systemd?" do
    before{ allow(subject).to receive(:windows?).and_return(false) }

    context "on windows" do
      before{ expect(subject).to receive(:windows?).and_return(true) }

      it "should return false" do
        expect(subject.systemd?).to be_falsey
      end
    end

    it "should return true if systemd is in use" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double(:result, stdout: "systemd"))
      expect(subject.systemd?).to be_truthy
    end

    it "should return false if systemd is not in use" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double(:result, stdout: "other"))
      expect(subject.systemd?).to be_falsey
    end
  end

  describe ".wsl_validate_matching_vagrant_versions!" do
    let(:exe_version){ Vagrant::VERSION.to_s }

    before do
      allow(Vagrant::Util::Which).to receive(:which).and_return(true)
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("vagrant.exe", "--version").
        and_return(double(exit_code: 0, stdout: "Vagrant #{exe_version}"))
    end

    it "should not raise an error" do
      Vagrant::Util::Platform.wsl_validate_matching_vagrant_versions!
    end

    context "when windows vagrant.exe is not installed" do
      before{ expect(Vagrant::Util::Which).to receive(:which).with("vagrant.exe").and_return(nil) }

      it "should not raise an error" do
        Vagrant::Util::Platform.wsl_validate_matching_vagrant_versions!
      end
    end

    context "when versions do not match" do
      let(:exe_version){ "1.9.9" }

      it "should raise an error" do
        expect {
          Vagrant::Util::Platform.wsl_validate_matching_vagrant_versions!
        }.to raise_error(Vagrant::Errors::WSLVagrantVersionMismatch)
      end
    end
  end

  describe ".windows_hyperv_admin?" do
    before { allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return(nil) }

    it "should return false when user is not in groups and cannot access Hyper-V" do
      expect(Vagrant::Util::Platform.windows_hyperv_admin?).to be_falsey
    end

    context "when VAGRANT_IS_HYPERV_ADMIN environment variable is set" do
      before { allow(ENV).to receive(:[]).with("VAGRANT_IS_HYPERV_ADMIN").and_return("1") }

      it "should return true" do
        expect(Vagrant::Util::Platform.windows_hyperv_admin?).to be_truthy
      end
    end

    context "when user is in the Hyper-V administators group" do
      it "should return true" do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return(["Value" => "S-1-5-32-578"].to_json)
        expect(Vagrant::Util::Platform.windows_hyperv_admin?).to be_truthy
      end
    end

    context "when user is in the Domain Admins group" do
      it "should return true" do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return(["Value" => "S-1-5-21-000-000-000-512"].to_json)
        expect(Vagrant::Util::Platform.windows_hyperv_admin?).to be_truthy
      end
    end

    context "when user has access to Hyper-V" do
      it "should return true" do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/GetCurrent/).and_return(nil)
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/Get-VMHost/).and_return("true")
        expect(Vagrant::Util::Platform.windows_hyperv_admin?).to be_truthy
      end
    end
  end

  describe ".windows_hyperv_enabled?" do
    it "should return true if enabled" do
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return('Enabled')

      expect(Vagrant::Util::Platform.windows_hyperv_enabled?).to be_truthy
    end

    it "should return false if disabled" do
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return('Disabled')

      expect(Vagrant::Util::Platform.windows_hyperv_enabled?).to be_falsey
    end

    it "should return false if PowerShell cannot be validated" do
      allow_any_instance_of(Vagrant::Errors::PowerShellInvalidVersion).to receive(:translate_error)
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_raise(Vagrant::Errors::PowerShellInvalidVersion)

      expect(Vagrant::Util::Platform.windows_hyperv_enabled?).to be_falsey
    end
  end

  context "within the WSL" do
    before{ allow(subject).to receive(:wsl?).and_return(true) }

    describe ".wsl_path?" do
      it "should return true when path is not within /mnt" do
        expect(subject.wsl_path?("/tmp")).to be(true)
      end

      it "should return false when path is within /mnt" do
        expect(subject.wsl_path?("/mnt/c")).to be(false)
      end
    end

    describe ".wsl_rootfs" do
      let(:appdata_path){ "C:\\Custom\\Path" }
      let(:registry_paths){ nil }

      before do
        allow(subject).to receive(:wsl_windows_appdata_local).and_return(appdata_path)
        allow(Tempfile).to receive(:new).and_return(double("tempfile", path: "file.path", close!: true))
        allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return(registry_paths)
      end

      context "when no instance information is in the registry" do
        before do
          expect(Dir).to receive(:open).with(/.*Custom.*Path.*/).and_yield(double("path", path: appdata_path))
          expect(File).to receive(:exist?).and_return(true)
        end

        it "should only check the lxrun path" do
          expect(subject.wsl_rootfs).to include(appdata_path)
        end
      end

      context "with instance information in the registry" do
        let(:registry_paths) { ["C:\\Path1", "C:\\Path2"].join("\r\n") }

        before do
          allow(Dir).to receive(:open).and_yield(double("path", path: appdata_path))
          allow(File).to receive(:exist?).and_return(false)
        end

        context "when no matches are detected" do
          it "should check all paths given" do
            expect(Dir).to receive(:open).and_yield(double("path", path: appdata_path)).exactly(3).times
            expect(File).to receive(:exist?).and_return(false).exactly(3).times
            expect{ subject.wsl_rootfs }.to raise_error(Vagrant::Errors::WSLRootFsNotFoundError)
          end

          it "should raise not found error" do
            expect{ subject.wsl_rootfs }.to raise_error(Vagrant::Errors::WSLRootFsNotFoundError)
          end
        end

        context "when file marker match found" do
          let(:matching_path){ registry_paths.split("\r\n").last }
          let(:matching_part){ matching_path.split("\\").last }

          before do
            allow(File).to receive(:exist?).with(/#{matching_part}/).and_return(true)
          end

          it "should return the matching path" do
            expect(Dir).to receive(:open).with(/#{matching_part}/).and_yield(double("path", path: matching_part))
            expect(subject.wsl_rootfs).to start_with(matching_path)
          end

          it "should return matching path when access error encountered" do
            expect(Dir).to receive(:open).with(/#{matching_part}/).and_raise(Errno::EACCES)
            expect(subject.wsl_rootfs).to start_with(matching_path)
          end
        end
      end

      context "when wslpath command success" do
        it "should check path returned by command" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 0, stdout: "/c/Custom/Path"))
          expect(Dir).to receive(:open).with(/^\/c\/Custom\/Path\//).and_yield(double("path", path: appdata_path))
          expect(File).to receive(:exist?).and_return(true)
          expect(subject.wsl_rootfs).to include(appdata_path)
        end
      end

      context "when wslpath command failed" do
        it "should check fallback path" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 1))
          expect(Dir).to receive(:open).with(/\/mnt\//).and_yield(double("path", path: appdata_path))
          expect(File).to receive(:exist?).and_return(true)
          expect(subject.wsl_rootfs).to include(appdata_path)
        end
      end

      context "when wslpath command raise error" do
        it "should check fallback path" do
          expect(Vagrant::Util::Subprocess).to receive(:execute).and_raise(Vagrant::Errors::CommandUnavailable, file: "wslpath")
          expect(Dir).to receive(:open).with(/\/mnt\//).and_yield(double("path", path: appdata_path))
          expect(File).to receive(:exist?).and_return(true)
          expect(subject.wsl_rootfs).to include(appdata_path)
        end
      end
    end

    describe ".wsl_to_windows_path" do
      let(:path){ "/home/vagrant/test" }

      context "when not within WSL" do
        before{ allow(subject).to receive(:wsl?).and_return(false) }

        it "should return the path unmodified" do
          expect(subject.wsl_to_windows_path(path)).to eq(path)
        end
      end

      context "when within WSL" do
        before{ allow(subject).to receive(:wsl?).and_return(true) }

        context "when windows access is not enabled" do
          before{ allow(subject).to receive(:wsl_windows_access?).and_return(false) }

          it "should return the path unmodified" do
            expect(subject.wsl_to_windows_path(path)).to eq(path)
          end
        end

        context "when windows access is enabled" do
          let(:rootfs_path){ "C:\\WSL\\rootfs" }

          before do
            allow(subject).to receive(:wsl_windows_access?).and_return(true)
            allow(subject).to receive(:wsl_rootfs).and_return(rootfs_path)
          end

          it "should generate expanded path when within WSL" do
            expect(subject.wsl_to_windows_path(path)).to eq("#{rootfs_path}#{path.gsub("/", "\\")}")
          end

          it "should generate direct path when outside the WSL" do
            expect(subject.wsl_to_windows_path("/mnt/c/vagrant")).to eq("c:\\vagrant")
          end

          it "should not modify path when already in windows format" do
            expect(subject.wsl_to_windows_path("C:\\vagrant")).to eq("C:\\vagrant")
          end

          context "when within lxrun generated WSL instance" do
            let(:rootfs_path){ "C:\\WSL\\lxss" }

            it "should not include rootfs when accessing home" do
              expect(subject.wsl_to_windows_path("/home/vagrant")).not_to include("rootfs")
            end

            it "should include rootfs when accessing non-home path" do
              expect(subject.wsl_to_windows_path("/tmp/test")).to include("rootfs")
            end

            it "should properly handle Pathname" do
              expect(subject.wsl_to_windows_path(Pathname.new("/tmp/test"))).to include("rootfs")
            end
          end

          context "when wslpath command success" do
            it "should return path returned by command" do
              expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 0, stdout: "C:\\Custom\\Path"))
              expect(subject.wsl_to_windows_path(path)).to eq("C:\\Custom\\Path")
            end
          end

          context "when wslpath command failed" do
            it "should return path by fallback" do
              expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 1))
              expect(subject.wsl_to_windows_path(path)).to eq("#{rootfs_path}#{path.gsub("/", "\\")}")
            end
          end

          context "when wslpath command raise error" do
            it "should return path by fallback" do
              expect(Vagrant::Util::Subprocess).to receive(:execute).and_raise(Vagrant::Errors::CommandUnavailable, file: "wslpath")
              expect(subject.wsl_to_windows_path(path)).to eq("#{rootfs_path}#{path.gsub("/", "\\")}")
            end
          end
        end
      end
    end

    describe ".wsl_windows_accessible_path" do
      context "when within WSL" do
        before do
          allow(subject).to receive(:wsl?).and_return(true)
          allow(subject).to receive(:wsl_windows_home).and_return("C:\\Users\\vagrant")
          allow(ENV).to receive(:[]).with("VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH").and_return(nil)
        end

        context "when wslpath command success" do
          it "should return path returned by command" do
            expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 0, stdout: "/d/vagrant"))
            expect(subject.wsl_windows_accessible_path.to_s).to eq("/d/vagrant")
          end
        end

        context "when wslpath command failed" do
          it "should return path by fallback" do
            expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double("process", exit_code: 1))
            expect(subject.wsl_windows_accessible_path.to_s).to eq("/mnt/c/Users/vagrant")
          end
        end

        context "when wslpath command raise error" do
          it "should return path by fallback" do
            expect(Vagrant::Util::Subprocess).to receive(:execute).and_raise(Vagrant::Errors::CommandUnavailable, file: "wslpath")
            expect(subject.wsl_windows_accessible_path.to_s).to eq("/mnt/c/Users/vagrant")
          end
        end
      end
    end

    describe ".wsl_drvfs_mounts" do
      let(:mount_output) { <<-EOF
rootfs on / type lxfs (rw,noatime)
sysfs on /sys type sysfs (rw,nosuid,nodev,noexec,noatime)
proc on /proc type proc (rw,nosuid,nodev,noexec,noatime)
none on /dev type tmpfs (rw,noatime,mode=755)
devpts on /dev/pts type devpts (rw,nosuid,noexec,noatime)
none on /run type tmpfs (rw,nosuid,noexec,noatime,mode=755)
none on /run/lock type tmpfs (rw,nosuid,nodev,noexec,noatime)
none on /run/shm type tmpfs (rw,nosuid,nodev,noatime)
none on /run/user type tmpfs (rw,nosuid,nodev,noexec,noatime,mode=755)
binfmt_misc on /proc/sys/fs/binfmt_misc type binfmt_misc (rw,noatime)
C: on /mnt/c type drvfs (rw,noatime)
EOF
      }

      before do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("mount").
          and_return(Vagrant::Util::Subprocess::Result.new(0, mount_output, ""))
      end

      it "should locate DrvFs mount path" do
        expect(subject.wsl_drvfs_mounts).to eq(["/mnt/c"])
      end

      context "when no DrvFs mounts exist" do
        let(:mount_output){ "" }

        it "should locate no paths" do
          expect(subject.wsl_drvfs_mounts).to eq([])
        end
      end
    end

    describe ".wsl_drvfs_path?" do
      before do
        expect(subject).to receive(:wsl_drvfs_mounts).and_return(["/mnt/c"])
      end

      it "should return true when path prefix is found" do
        expect(subject.wsl_drvfs_path?("/mnt/c/some/path")).to be_truthy
      end

      it "should return false when path prefix is not found" do
        expect(subject.wsl_drvfs_path?("/home/vagrant/some/path")).to be_falsey
      end
    end
  end

  describe ".unix_windows_path" do
    it "takes a windows path and returns a POSIX-like path" do
      expect(subject.unix_windows_path("C:\\Temp\\Windows")).to eq("C:/Temp/Windows")
    end
  end
end
