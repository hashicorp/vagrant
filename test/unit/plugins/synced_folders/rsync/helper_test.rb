# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/synced_folders/rsync/helper")

describe VagrantPlugins::SyncedFolderRSync::RsyncHelper do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  subject { described_class }

  before do
    allow(machine).to receive(:guest).and_return(guest)

    # Don't do all the crazy Cygwin stuff
    allow(Vagrant::Util::Platform).to receive(:cygwin_path) do |path, **opts|
      path
    end
  end

  describe "#exclude_to_regexp" do
    let(:path) { "/foo/bar" }

    it "converts a directory match" do
      expected_regex = /foo\/.*/
      expect(described_class.exclude_to_regexp("foo/")).
        to eq(/foo\/.*/)
      expect(path).to match(expected_regex)
    end

    it "converts the start anchor" do
      expected_regex = /^\/foo\//
      expect(described_class.exclude_to_regexp("/foo")).
        to eq(expected_regex)
      expect(path).to match(expected_regex)
    end

    it "converts the **" do
      expected_regex = /fo.*o.*/
      expect(described_class.exclude_to_regexp("fo**o")).
        to eq(expected_regex)
      expect(path).to match(expected_regex)
    end

    it "converts the *" do
      expected_regex = /fo*o.*/
      expect(described_class.exclude_to_regexp("fo*o")).
        to eq(expected_regex)
      expect(path).to match(expected_regex)
    end
  end

  describe "#rsync_single" do
    let(:result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

    let(:ssh_info) {{
      private_key_path: [],
    }}
    let(:opts)      {{
      hostpath: "/foo",
    }}
    let(:ui)        { machine.ui }

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute){ result }

      allow(guest).to receive(:capability?){ false }
    end

    it "doesn't raise an error if it succeeds" do
      subject.rsync_single(machine, ssh_info, opts)
    end

    it "doesn't call cygwin_path on non-Windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(false)
      expect(Vagrant::Util::Platform).not_to receive(:cygwin_path)
      subject.rsync_single(machine, ssh_info, opts)
    end

    it "calls cygwin_path on Windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      expect(Vagrant::Util::Platform).to receive(:cygwin_path).and_return("foo")

      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args[args.length - 3]).to eql("foo/")
      }.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "raises an error if the exit code is non-zero" do
      allow(Vagrant::Util::Subprocess).to receive(:execute)
        .and_return(Vagrant::Util::Subprocess::Result.new(1, "", ""))

      expect {subject.rsync_single(machine, ssh_info, opts) }.
        to raise_error(Vagrant::Errors::RSyncError)
    end

    context "host and guest paths" do
      it "syncs the hostpath to the guest path" do
        opts[:hostpath] = "/foo"
        opts[:guestpath] = "/bar"

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
          expect(args[args.length - 2]).to include("/bar")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "expands the hostpath relative to the root path" do
        opts[:hostpath] = "foo"
        opts[:guestpath] = "/bar"

        hostpath_expanded = File.expand_path(opts[:hostpath], machine.env.root_path)

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args[args.length - 3]).to eql("#{hostpath_expanded}/")
          expect(args[args.length - 2]).to include("/bar")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    it "executes within the root path" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args.last).to be_kind_of(Hash)

        opts = args.last
        expect(opts[:workdir]).to eql(machine.env.root_path.to_s)
      }.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "executes the rsync_pre capability first if it exists" do
      expect(guest).to receive(:capability?).with(:rsync_pre).and_return(true)
      expect(guest).to receive(:capability).with(:rsync_pre, opts).ordered
      expect(Vagrant::Util::Subprocess).to receive(:execute).ordered.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "executes the rsync_post capability after if it exists" do
      expect(guest).to receive(:capability?).with(:rsync_post).and_return(true)
      expect(Vagrant::Util::Subprocess).to receive(:execute).ordered.and_return(result)
      expect(guest).to receive(:capability).with(:rsync_post, opts).ordered

      subject.rsync_single(machine, ssh_info, opts)
    end

    context "with rsync_post capability" do
      before do
        allow(guest).to receive(:capability?).with(:rsync_post).and_return(true)
        allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(result)
      end

      it "should raise custom error when capability errors" do
        expect(guest).to receive(:capability).with(:rsync_post, opts).
          and_raise(Vagrant::Errors::VagrantError)

        expect { subject.rsync_single(machine, ssh_info, opts) }.
          to raise_error(Vagrant::Errors::RSyncPostCommandError)
      end

      it "should populate :owner and :group from ssh_info[:username] when values are nil" do
        opts[:owner] = nil
        opts[:group] = nil
        ssh_info[:username] = "userfromssh"

        expect(guest).to receive(:capability).with(:rsync_post, a_hash_including(
          owner: "userfromssh",
          group: "userfromssh",
        ))

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "with rsync_ownership option" do
      let(:rsync_local_version) { "3.1.1" }
      let(:rsync_remote_version) { "3.1.1" }
      let(:rsync_result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

      before do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("rsync", "--version").and_return(Vagrant::Util::Subprocess::Result.new(0, " version #{rsync_local_version} ", ""))
        allow(machine.communicate).to receive(:execute).with(/--version/).and_yield(:stdout, " version #{rsync_remote_version} ")
        allow(Vagrant::Util::Subprocess).to receive(:execute).with("rsync", any_args).and_return(rsync_result)
        opts[:rsync_ownership] = true
      end

      after { subject.reset! }

      it "should use the rsync --chown flag" do
        expect(Vagrant::Util::Subprocess).to receive(:execute) { |*args|
          expect(args.detect{|a| a.include?("--chown")}).to be_truthy
          rsync_result
        }
        subject.rsync_single(machine, ssh_info, opts)
      end

      it "should set the chown option to false" do
        expect(opts.has_key?(:chown)).to eq(false)
        subject.rsync_single(machine, ssh_info, opts)
        expect(opts[:chown]).to eq(false)
      end

      context "when local rsync version does not support --chown" do
        let(:rsync_local_version) { "2.0" }

        it "should not use the --chown flag" do
          expect(Vagrant::Util::Subprocess).to receive(:execute) { |*args|
            expect(args.detect{|a| a.include?("--chown")}).to be_falsey
            rsync_result
          }
          subject.rsync_single(machine, ssh_info, opts)
        end
      end

      context "when remote rsync version does not support --chown" do
        let(:rsync_remote_version) { "2.0" }

        it "should not use the --chown flag" do
          expect(Vagrant::Util::Subprocess).to receive(:execute) { |*args|
            expect(args.detect{|a| a.include?("--chown")}).to be_falsey
            rsync_result
          }
          subject.rsync_single(machine, ssh_info, opts)
        end
      end
    end

    context "excluding files" do
      it "excludes files if given as a string" do
        opts[:exclude] = "foo"

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          index = args.find_index("foo")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "excludes multiple files" do
        opts[:exclude] = ["foo", "bar"]

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          index = args.find_index("foo")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")

          index = args.find_index("bar")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "custom arguments" do
      it "uses the default arguments if not given" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args[1]).to eq("--verbose")
          expect(args[2]).to eq("--archive")
          expect(args[3]).to eq("--delete")

          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "uses the custom arguments if given" do
        opts[:args] = ["--verbose", "-z"]

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args[1]).to eq("--verbose")
          expect(args[2]).to eq("-z")

          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
        }.and_return(result)

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "control sockets" do
      it "creates a tmp dir" do
        allow(Vagrant::Util::Platform).to receive(:windows?).and_return(false)
        allow(Dir).to receive(:mktmpdir).with("vagrant-rsync-").
          and_return("/tmp/vagrant-rsync-12345")

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args[9]).to include("ControlPath=/tmp/vagrant-rsync-12345")
        }.and_return(result)

        expect(FileUtils).to receive(:remove_entry_secure).with("/tmp/vagrant-rsync-12345", true).and_return(true)
        subject.rsync_single(machine, ssh_info, opts)
      end

      it "does not create tmp dir on windows platforms" do
        allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
        allow(Dir).to receive(:mktmpdir).with("vagrant-rsync-").
          and_return("/tmp/vagrant-rsync-12345")

        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
          expect(args).not_to include("ControlPath=/tmp/vagrant-rsync-12345")
        }.and_return(result)

        expect(FileUtils).not_to receive(:remove_entry_secure).with("/tmp/vagrant-rsync-12345", true)
        subject.rsync_single(machine, ssh_info, opts)
      end
    end
  end

  describe "#rsync_single with custom ssh_info" do
    let(:result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

    let(:ssh_info) {{
      :private_key_path => ['/path/to/key'],
      :keys_only        => true,
      :verify_host_key  => false,
    }}
    let(:opts)      {{
      hostpath: "/foo",
    }}
    let(:ui)        { machine.ui }

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute){ result }

      allow(guest).to receive(:capability?){ false }
    end

    context "with extra args defined" do
      before { ssh_info[:extra_args] = ["-o", "Compression=yes"] }

      it "appends the extra arguments from ssh_info" do
        expect(Vagrant::Util::Subprocess).to receive(:execute) { |*args|
          cmd = args.detect { |a| a.is_a?(String) && a.start_with?("ssh") }
          expect(cmd).to be
          expect(cmd).to include("-o Compression=yes")
        }.and_return(result)
        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "with an IPv6 address" do
      before { ssh_info[:host] = "fe00::0" }

      it "formats the address correctly" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, "@[#{ssh_info[:host]}]:''", instance_of(Hash))
        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "with an IPv4 address" do
      before { ssh_info[:host] = "127.0.0.1" }

      it "formats the address correctly" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, "@#{ssh_info[:host]}:''", instance_of(Hash))
        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    it "includes IdentitiesOnly, StrictHostKeyChecking, and UserKnownHostsFile with defaults" do

      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args[9]).to include('IdentitiesOnly')
        expect(args[9]).to include('StrictHostKeyChecking')
        expect(args[9]).to include('UserKnownHostsFile')
        expect(args[9]).to include("-i '/path/to/key'")
      }.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "includes StrictHostKeyChecking, and UserKnownHostsFile when verify_host_key is false" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args[9]).to include('StrictHostKeyChecking')
        expect(args[9]).to include('UserKnownHostsFile')
      }.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "includes StrictHostKeyChecking, and UserKnownHostsFile when verify_host_key is :never" do
      ssh_info[:verify_host_key] = :never

      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args) { |*args|
        expect(args[9]).to include('StrictHostKeyChecking')
        expect(args[9]).to include('UserKnownHostsFile')
      }.and_return(result)

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "omits IdentitiesOnly with keys_only = false" do
      ssh_info[:keys_only] = false

      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        expect(args[9]).not_to include('IdentitiesOnly')
        result
      end

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "omits StrictHostKeyChecking and UserKnownHostsFile with paranoid = true" do
      ssh_info[:keys_only] = false

      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        expect(args[9]).not_to include('StrictHostKeyChecking ')
        expect(args[9]).not_to include('UserKnownHostsFile ')
        result
      end

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "includes custom ssh config when set" do
      ssh_info[:config] = "/path/to/ssh/config"
      expect(Vagrant::Util::Subprocess).to receive(:execute) do |*args|
        ssh_config_args = "-F /path/to/ssh/config"
        expect(args.any?{|a| a.include?(ssh_config_args)}).to be_truthy
        result
      end
      subject.rsync_single(machine, ssh_info, opts)
    end
  end

  describe ".rsync_chown_support?" do
    let(:local_version) { "3.1.1" }
    let(:remote_version) { "3.1.1" }

    before do
      allow(subject).to receive(:local_rsync_version).and_return(local_version)
      allow(subject).to receive(:machine_rsync_version).and_return(remote_version)
    end

    it "should return when local and remote versions support chown" do
      expect(subject.rsync_chown_support?(machine)).to be_truthy
    end

    context "when local version does not support chown" do
      let(:local_version) { "2.0" }

      it "should return false" do
        expect(subject.rsync_chown_support?(machine)).to be_falsey
      end
    end

    context "when remote version does not support chown" do
      let(:remote_version) { "2.0" }

      it "should return false" do
        expect(subject.rsync_chown_support?(machine)).to be_falsey
      end
    end

    context "when both local and remote versions do not support chown" do
      let(:local_version) { "2.0" }
      let(:remote_version) { "2.0" }

      it "should return false" do
        expect(subject.rsync_chown_support?(machine)).to be_falsey
      end
    end
  end

  describe ".machine_rsync_version" do
    let(:version_output) {
      <<-EOV
      rsync  version 3.1.3  protocol version 31
      Copyright (C) 1996-2018 by Andrew Tridgell, Wayne Davison, and others.
      Web site: http://rsync.samba.org/
      Capabilities:
      64-bit files, 64-bit inums, 64-bit timestamps, 64-bit long ints,
      socketpairs, hardlinks, symlinks, IPv6, batchfiles, inplace,
      append, ACLs, xattrs, iconv, symtimes, prealloc

      rsync comes with ABSOLUTELY NO WARRANTY.  This is free software, and you
      are welcome to redistribute it under certain conditions.  See the GNU
      General Public Licence for details.
      EOV
    }

    before do
      allow(machine.communicate).to receive(:execute).with(/--version/).
        and_yield(:stdout, version_output)
      allow(guest).to receive(:capability?).and_return(false)
    end

    it "should extract the version string" do
      expect(subject.machine_rsync_version(machine)).to eq("3.1.3")
    end

    context "when version output is an unknown format" do
      let(:version_output) { "unknown" }

      it "should return nil value" do
        expect(subject.machine_rsync_version(machine)).to be_nil
      end
    end

    context "with guest rsync_command capability" do
      let(:rsync_path) { "custom_rsync" }

      before do
        allow(guest).to receive(:capability?).with(:rsync_command).
          and_return(true)
        allow(guest).to receive(:capability).with(:rsync_command).
          and_return(rsync_path)
      end

      it "should use custom rsync_path" do
        expect(machine.communicate).to receive(:execute).
          with("#{rsync_path} --version").and_yield(:stdout, version_output)
        subject.machine_rsync_version(machine)
      end
    end
  end

  describe ".local_rsync_version" do
    let(:version_output) {
      <<-EOV
      rsync  version 3.1.3  protocol version 31
      Copyright (C) 1996-2018 by Andrew Tridgell, Wayne Davison, and others.
      Web site: http://rsync.samba.org/
      Capabilities:
      64-bit files, 64-bit inums, 64-bit timestamps, 64-bit long ints,
      socketpairs, hardlinks, symlinks, IPv6, batchfiles, inplace,
      append, ACLs, xattrs, iconv, symtimes, prealloc

      rsync comes with ABSOLUTELY NO WARRANTY.  This is free software, and you
      are welcome to redistribute it under certain conditions.  See the GNU
      General Public Licence for details.
      EOV
    }
    let(:result) { Vagrant::Util::Subprocess::Result.new(0, version_output, "") }

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with("rsync", "--version").
        and_return(result)
    end

    after { subject.reset! }

    it "should extract the version string" do
      expect(subject.local_rsync_version).to eq("3.1.3")
    end

    it "should cache the version lookup" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("rsync", "--version").
        and_return(result).once
      expect(subject.local_rsync_version).to eq("3.1.3")
      expect(subject.local_rsync_version).to eq("3.1.3")
    end

    context "when version output is an unknown format" do
      let(:version_output) { "unknown" }

      it "should return nil value" do
        expect(subject.local_rsync_version).to be_nil
      end
    end
  end
end
