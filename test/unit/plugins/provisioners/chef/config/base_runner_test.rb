require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/base_runner")

describe VagrantPlugins::Chef::Config::BaseRunner do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#arguments" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.arguments).to be(nil)
    end
  end

  describe "#attempts" do
    it "defaults to 1" do
      subject.finalize!
      expect(subject.attempts).to eq(1)
    end
  end

  describe "#custom_config_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.custom_config_path).to be(nil)
    end
  end

  describe "#environment" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.environment).to be(nil)
    end
  end

  describe "#encrypted_data_bag_secret_key_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.encrypted_data_bag_secret_key_path).to be(nil)
    end
  end

  describe "#formatter" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.formatter).to be(nil)
    end
  end

  describe "#http_proxy" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.http_proxy).to be(nil)
    end
  end

  describe "#http_proxy_user" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.http_proxy_user).to be(nil)
    end
  end

  describe "#http_proxy_pass" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.http_proxy_pass).to be(nil)
    end
  end

  describe "#https_proxy" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.https_proxy).to be(nil)
    end
  end

  describe "#https_proxy_user" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.https_proxy_user).to be(nil)
    end
  end

  describe "#https_proxy_pass" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.https_proxy_pass).to be(nil)
    end
  end

  describe "#log_level" do
    it "defaults to :info" do
      subject.finalize!
      expect(subject.log_level).to be(:info)
    end

    it "is converted to a symbol" do
      subject.log_level = "foo"
      subject.finalize!
      expect(subject.log_level).to eq(:foo)
    end
  end

  describe "#no_proxy" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.no_proxy).to be(nil)
    end
  end

  describe "#node_name" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.node_name).to be(nil)
    end
  end

  describe "#provisioning_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.provisioning_path).to be(nil)
    end
  end

  describe "#file_backup_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.file_backup_path).to be(nil)
    end
  end

  describe "#file_cache_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.file_cache_path).to be(nil)
    end
  end

  describe "#verbose_logging" do
    it "defaults to false" do
      subject.finalize!
      expect(subject.verbose_logging).to be(false)
    end
  end

  describe "#enable_reporting" do
    it "defaults to true" do
      subject.finalize!
      expect(subject.enable_reporting).to be(true)
    end
  end

  describe "#run_list" do
    it "defaults to an empty array" do
      subject.finalize!
      expect(subject.run_list).to be_a(Array)
      expect(subject.run_list).to be_empty
    end
  end

  describe "#json" do
    it "defaults to an empty hash" do
      subject.finalize!
      expect(subject.json).to be_a(Hash)
      expect(subject.json).to be_empty
    end
  end

  describe "#add_recipe" do
    context "when the prefix is given" do
      it "adds the value to the run_list" do
        subject.add_recipe("recipe[foo::bar]")
        expect(subject.run_list).to eq %w(recipe[foo::bar])
      end
    end

    context "when the prefix is not given" do
      it "adds the prefixed value to the run_list" do
        subject.add_recipe("foo::bar")
        expect(subject.run_list).to eq %w(recipe[foo::bar])
      end
    end
  end

  describe "#add_role" do
    context "when the prefix is given" do
      it "adds the value to the run_list" do
        subject.add_role("role[foo]")
        expect(subject.run_list).to eq %w(role[foo])
      end
    end

    context "when the prefix is not given" do
      it "adds the prefixed value to the run_list" do
        subject.add_role("foo")
        expect(subject.run_list).to eq %w(role[foo])
      end
    end
  end

   describe "#validate_base" do
    context "when #custom_config_path does not exist" do
      let(:path) do
        next "/path/to/file" if !Vagrant::Util::Platform.windows?
        "C:/path/to/file"
      end

      before do
        allow(File).to receive(:file?)
          .with(path)
          .and_return(false)

        allow(machine).to receive(:env)
          .and_return(double("env",
            root_path: "",
          ))
      end

      it "returns an error" do
        subject.custom_config_path = path
        subject.finalize!

        expect(subject.validate_base(machine))
          .to eq ['Path specified for "custom_config_path" does not exist.']
      end
    end
  end

  describe "#merge" do
    it "merges the json hash" do
      a = described_class.new.tap do |i|
        i.json = { "foo" => "bar" }
      end
      b = described_class.new.tap do |i|
        i.json = { "zip" => "zap" }
      end

      result = a.merge(b)
      expect(result.json).to eq(
        "foo" => "bar",
        "zip" => "zap",
      )
    end

    it "appends the run_list array" do
      a = described_class.new.tap do |i|
        i.run_list = ["recipe[foo::bar]"]
      end
      b = described_class.new.tap do |i|
        i.run_list = ["recipe[zip::zap]"]
      end

      result = a.merge(b)
      expect(result.run_list).to eq %w(
        recipe[foo::bar]
        recipe[zip::zap]
      )
    end
  end
end
