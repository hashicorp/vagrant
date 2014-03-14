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
    machine.stub(guest: guest)

    # Don't do all the crazy Cygwin stuff
    allow(Vagrant::Util::Platform).to receive(:cygwin_path) do |path, **opts|
      path
    end
  end

  describe "#exclude_to_regexp" do
    let(:path) { "/foo/bar" }

    it "converts a directory match" do
      expect(described_class.exclude_to_regexp(path, "foo/")).
        to eq(/^#{Regexp.escape(path)}\/.*foo\//)
    end

    it "converts the start anchor" do
      expect(described_class.exclude_to_regexp(path, "/foo")).
        to eq(/^\/foo\/bar\/foo/)
    end

    it "converts the **" do
      expect(described_class.exclude_to_regexp(path, "fo**o")).
        to eq(/^#{Regexp.escape(path)}\/.*fo.*o/)
    end

    it "converts the *" do
      expect(described_class.exclude_to_regexp(path, "fo*o")).
        to eq(/^#{Regexp.escape(path)}\/.*fo[^\/]*o/)
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
      Vagrant::Util::Subprocess.stub(execute: result)

      guest.stub(capability?: false)
    end

    it "doesn't raise an error if it succeeds" do
      subject.rsync_single(machine, ssh_info, opts)
    end

    it "doesn't call cygwin_path on non-Windows" do
      Vagrant::Util::Platform.stub(windows?: false)
      expect(Vagrant::Util::Platform).not_to receive(:cygwin_path)
      subject.rsync_single(machine, ssh_info, opts)
    end

    it "calls cygwin_path on Windows" do
      Vagrant::Util::Platform.stub(windows?: true)
      expect(Vagrant::Util::Platform).to receive(:cygwin_path).and_return("foo")

      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        expect(args[args.length - 3]).to eql("foo/")
      }

      subject.rsync_single(machine, ssh_info, opts)
    end

    it "raises an error if the exit code is non-zero" do
      Vagrant::Util::Subprocess.stub(
        execute: Vagrant::Util::Subprocess::Result.new(1, "", ""))

      expect {subject.rsync_single(machine, ssh_info, opts) }.
        to raise_error(Vagrant::Errors::RSyncError)
    end

    context "host and guest paths" do
      it "syncs the hostpath to the guest path" do
        opts[:hostpath] = "/foo"
        opts[:guestpath] = "/bar"

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
          expect(args[args.length - 2]).to include("/bar")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "expands the hostpath relative to the root path" do
        opts[:hostpath] = "foo"
        opts[:guestpath] = "/bar"

        hostpath_expanded = File.expand_path(opts[:hostpath], machine.env.root_path)

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args[args.length - 3]).to eql("#{hostpath_expanded}/")
          expect(args[args.length - 2]).to include("/bar")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    it "executes within the root path" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
        expect(args.last).to be_kind_of(Hash)

        opts = args.last
        expect(opts[:workdir]).to eql(machine.env.root_path.to_s)
      }

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

    context "excluding files" do
      it "excludes files if given as a string" do
        opts[:exclude] = "foo"

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          index = args.find_index("foo")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "excludes multiple files" do
        opts[:exclude] = ["foo", "bar"]

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          index = args.find_index("foo")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")

          index = args.find_index("bar")
          expect(index).to be > 0
          expect(args[index-1]).to eql("--exclude")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end
    end

    context "custom arguments" do
      it "uses the default arguments if not given" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args[1]).to eq("--verbose")
          expect(args[2]).to eq("--archive")
          expect(args[3]).to eq("--delete")

          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end

      it "uses the custom arguments if given" do
        opts[:args] = ["--verbose", "-z"]

        expect(Vagrant::Util::Subprocess).to receive(:execute).with { |*args|
          expect(args[1]).to eq("--verbose")
          expect(args[2]).to eq("-z")

          expected = Vagrant::Util::Platform.fs_real_path("/foo").to_s
          expect(args[args.length - 3]).to eql("#{expected}/")
        }

        subject.rsync_single(machine, ssh_info, opts)
      end
    end
  end
end
