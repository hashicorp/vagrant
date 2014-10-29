require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/harmony/config")
require Vagrant.source_root.join("plugins/pushes/harmony/push")

describe VagrantPlugins::HarmonyPush::Push do
  include_context "unit"

  let(:config) do
    VagrantPlugins::HarmonyPush::Config.new.tap do |c|
      c.finalize!
    end
  end

  let(:machine) { double("machine") }

  subject { described_class.new(machine, config) }

  before do
    # Stub this right away to avoid real execs
    allow(Vagrant::Util::SafeExec).to receive(:exec)
  end

  describe "#push" do
    it "pushes with the uploader" do
      allow(subject).to receive(:uploader_path).and_return("foo")

      expect(subject).to receive(:execute).with("foo")

      subject.push
    end

    it "raises an exception if the uploader couldn't be found" do
      expect(subject).to receive(:uploader_path).and_return(nil)

      expect { subject.push }.to raise_error(
        VagrantPlugins::HarmonyPush::Errors::UploaderNotFound)
    end
  end

  describe "#execute" do
    let(:app) { "foo/bar" }

    before do
      config.app = app
    end

    it "sends the basic flags" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", app, ".")

      subject.execute("foo")
    end

    it "doesn't send VCS if disabled" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", app, ".")

      config.vcs = false
      subject.execute("foo")
    end

    it "sends includes" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-include", "foo", "-include", "bar", app, ".")

      config.include = ["foo", "bar"]
      subject.execute("foo")
    end

    it "sends excludes" do
      expect(Vagrant::Util::SafeExec).to receive(:exec).
        with("foo", "-vcs", "-exclude", "foo", "-exclude", "bar", app, ".")

      config.exclude = ["foo", "bar"]
      subject.execute("foo")
    end
  end

  describe "#uploader_path" do
    it "should return the configured path if set" do
      config.uploader_path = "foo"
      expect(subject.uploader_path).to eq("foo")
    end

    it "should look up the uploader via PATH if not set" do
      allow(Vagrant).to receive(:in_installer?).and_return(false)

      expect(Vagrant::Util::Which).to receive(:which).
        with(described_class.const_get(:UPLOADER_BIN)).
        and_return("bar")

      expect(subject.uploader_path).to eq("bar")
    end

    it "should return nil if its not found anywhere" do
      allow(Vagrant).to receive(:in_installer?).and_return(false)
      allow(Vagrant::Util::Which).to receive(:which).and_return(nil)

      expect(subject.uploader_path).to be_nil
    end
  end
end
