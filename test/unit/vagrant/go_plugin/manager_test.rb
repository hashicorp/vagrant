require_relative "../../base"

describe Vagrant::GoPlugin::Manager do
  include_context "unit"

  let(:env) do
    test_env.vagrantfile("")
    test_env.create_vagrant_env
  end

  before do
    allow(FileUtils).to receive(:mkdir_p)
  end

  describe ".instance" do
    it "should return instance of manager" do
      expect(described_class.instance).to be_a(described_class)
    end

    it "should cache instance" do
      expect(described_class.instance).to be(described_class.instance)
    end
  end

  describe ".new" do
    it "should create the installation directory" do
      expect(FileUtils).to receive(:mkdir_p).with(Vagrant::GoPlugin::INSTALL_DIRECTORY)
      subject
    end

    it "should create installation temporary directory" do
      expect(FileUtils).to receive(:mkdir_p).with(/tmp$/)
      subject
    end

    it "should generate user state file" do
      expect(subject.user_file).to be_a(Vagrant::Plugin::StateFile)
    end
  end

  describe "#globalize!" do
    let(:entries) { [double("entry1"), double("entry2")] }

    before do
      allow(File).to receive(:directory?).and_return(false)
      allow(Dir).to receive(:glob).and_return(entries)
      allow(Vagrant::GoPlugin).to receive_message_chain(:interface, :register_plugins)
    end

    context "when entries are not directories" do
      before { allow(File).to receive(:directory?).and_return(false) }

      it "should not load any plugins" do
        interface = double("interface", register_plugins: nil)
        allow(Vagrant::GoPlugin).to receive(:interface).and_return(interface)
        expect(interface).not_to receive(:load_plugins)
        subject.globalize!
      end
    end

    context "when entries are directories" do
      before { allow(File).to receive(:directory?).and_return(true) }

      it "should load all entries" do
        expect(Vagrant::GoPlugin).to receive_message_chain(:interface, :load_plugins).with(entries.first)
        expect(Vagrant::GoPlugin).to receive_message_chain(:interface, :load_plugins).with(entries.last)
        subject.globalize!
      end
    end

    it "should register plugins after loading" do
      expect(Vagrant::GoPlugin).to receive_message_chain(:interface, :register_plugins)
      subject.globalize!
    end
  end

  describe "#localize!" do
  end

  describe "#install_plugin" do
    let(:plugin_name) { "test_plugin_name" }
    let(:remote_source) { double("remote_source") }
    let(:downloader) { double("downloader", download!: nil) }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      allow(Dir).to receive(:mktmpdir)
      allow(Vagrant::Util::Downloader).to receive(:new).and_return(downloader)
      allow(Zip::File).to receive(:open)
    end

    after { subject.install_plugin(plugin_name, remote_source) }

    it "should create plugin directory for plugin name" do
      expect(FileUtils).to receive(:mkdir_p).with(/test_plugin_name$/)
    end

    it "should create a temporary directory to download and unpack" do
      expect(Dir).to receive(:mktmpdir).with(/go-plugin/, any_args)
    end

    it "should download the remote file" do
      expect(Dir).to receive(:mktmpdir).with(any_args).and_yield("tmpdir")
      expect(downloader).to receive(:download!)
    end

    it "should unzip the downloaded file" do
      expect(Dir).to receive(:mktmpdir).with(any_args).and_yield("tmpdir")
      expect(Zip::File).to receive(:open).with(/plugin.zip/)
    end

    it "should add the plugin to the user file" do
      expect(subject.user_file).to receive(:add_go_plugin).and_call_original
      expect(subject.user_file.has_go_plugin?("test_plugin_name")).to be_truthy
    end
  end

  describe "#uninstall_plugin" do
    let(:plugin_name) { "test_plugin_name" }

    before do
      allow(File).to receive(:directory?).and_call_original
      allow(FileUtils).to receive(:rm_rf)
    end

    after { subject.uninstall_plugin(plugin_name) }

    it "should remove plugin path when installed" do
      expect(File).to receive(:directory?).with(/test_plugin_name/).and_return(true)
      expect(FileUtils).to receive(:rm_rf).with(/test_plugin_name/)
    end

    it "should not remove plugin path when not installed" do
      expect(File).to receive(:directory?).with(/test_plugin_name/).and_return(false)
      expect(FileUtils).not_to receive(:rm_rf).with(/test_plugin_name/)
    end

    it "should have plugin name removed from user file when installed" do
      expect(File).to receive(:directory?).with(/test_plugin_name/).and_return(true)
      expect(subject.user_file).to receive(:remove_go_plugin).with(plugin_name)
    end

    it "should have plugin name removed from user file when not installed" do
      expect(File).to receive(:directory?).with(/test_plugin_name/).and_return(false)
      expect(subject.user_file).to receive(:remove_go_plugin).with(plugin_name)
    end
  end
end
