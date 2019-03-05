require_relative "../../base"

describe Vagrant::GoPlugin::Core do
  include_context "unit"

  let(:subject_class) { Class.new.tap { |c| c.include(described_class) } }
  let(:subject) { subject_class.new }

  let(:name)     { "foo" }
  let(:provider) { new_provider_mock }
  let(:provider_cls) do
    obj = double("provider_cls")
    allow(obj).to receive(:new).and_return(provider)
    obj
  end
  let(:provider_config) { Object.new }
  let(:provider_name) { :test }
  let(:provider_options) { {} }
  let(:base)     { false }
  let(:box) do
    double("box",
      name: "foo",
      provider: :dummy,
      version: "1.0",
      directory: "box dir",
      metadata: nil,
      metadata_url: nil)
  end

  let(:config)   { env.vagrantfile.config }
  let(:data_dir) { Pathname.new(Dir.mktmpdir("vagrant-machine-data-dir")) }
  let(:env)      do
    # We need to create a Vagrantfile so that this test environment
    # has a proper root path
    test_env.vagrantfile("")

    # Create the Vagrant::Environment instance
    test_env.create_vagrant_env
  end

  let(:test_env) { isolated_environment }
  let(:machine) {
    Vagrant::Machine.new(name, provider_name, provider_cls, provider_config,
      provider_options, config, data_dir, box,
      env, env.vagrantfile, base)
  }

  def new_provider_mock
    double("provider").tap do |obj|
      allow(obj).to receive(:_initialize)
        .with(provider_name, anything).and_return(nil)
      allow(obj).to receive(:machine_id_changed).and_return(nil)
      allow(obj).to receive(:state).and_return(Vagrant::MachineState.new(
        :created, "", ""))
    end
  end

  describe "#dump_machine" do
    it "should raise error when argument is not a Vagrant Machine" do
      expect { subject.dump_machine(:value) }.to raise_error(TypeError)
    end

    it "should dump machine to JSON string" do
      expect(subject.dump_machine(machine)).to be_a(String)
    end

    it "should dump machine information" do
      val = subject.dump_machine(machine)
      result = JSON.load(val)
      expect(result["name"]).to eq(machine.name)
      expect(result["provider_name"]).to eq(machine.provider_name.to_s)
      expect(result["data_dir"]).to eq(machine.data_dir.to_s)
    end

    it "should dump box information" do
      val = subject.dump_machine(machine)
      result = JSON.load(val)
      expect(result["box"]).to_not be_nil
      expect(result["box"]["name"]).to eq("foo")
    end

    it "should dump environment information" do
      val = subject.dump_machine(machine)
      result = JSON.load(val)
      expect(result["environment"]).to_not be_nil
      expect(result["environment"]["cwd"]).to eq(machine.env.cwd.to_s)
    end
  end

  describe "#dump_environment" do
    it "should dump environment to Hash" do
      expect(subject.dump_environment(env)).to be_a(Hash)
    end

    it "should include environment information" do
      result = subject.dump_environment(env)
      expect(result[:cwd]).to eq(env.cwd)
      expect(result[:data_dir]).to eq(env.data_dir)
    end
  end

  describe "#load_machine" do
    it "should set ID if ID has changed" do
      expect(machine).to receive(:id=).with("newid")
      subject.load_machine({id: "newid"}, machine)
    end

    it "should not set ID if ID has not changed" do
      expect(machine).not_to receive(:id=)
      subject.load_machine({id: machine.id}, machine)
    end
  end
end

describe Vagrant::GoPlugin::DirectGoPlugin do
  let(:subject_class) { Class.new.tap { |c| c.include(described_class) } }
  let(:subject) { subject_class.new }

  describe ".go_plugin_name" do
    it "should return nil by default" do
      expect(subject_class.go_plugin_name).to be_nil
    end

    it "should return assigned name when assigned" do
      subject_class.go_plugin_name = :test
      expect(subject_class.go_plugin_name).to eq(:test)
    end
  end

  describe ".go_plugin_name=" do
    it "should allow for setting the plugin name" do
      subject_class.go_plugin_name = :test_plugin
      expect(subject_class.go_plugin_name).to eq(:test_plugin)
    end

    it "should raise error when name has already been set" do
      subject_class.go_plugin_name = :test_plugin
      expect {
        subject_class.go_plugin_name = :different_plugin
      }.to raise_error(ArgumentError)
    end
  end

  describe ".plugin_name" do
    it "should proxy to .go_plugin_name" do
      expect(subject_class).to receive(:go_plugin_name)
      subject_class.plugin_name
    end
  end

  describe ".name" do
    it "should default to empty string" do
      expect(subject_class.name).to eq("")
    end

    it "should camel case the go_plugin_name" do
      subject_class.go_plugin_name = "test_vagrant_plugin"
      expect(subject_class.name).to eq("TestVagrantPlugin")
    end
  end

  describe "#plugin_name" do
    it "should proxy to .go_plugin_name" do
      expect(subject_class).to receive(:go_plugin_name)
      subject.plugin_name
    end
  end
end

describe Vagrant::GoPlugin::TypedGoPlugin do
  let(:subject_class) { Class.new.tap { |c| c.include(described_class) } }
  let(:subject) { subject_class.new }

  it "should include DirectGoPlugin" do
    expect(subject_class.ancestors).to include(Vagrant::GoPlugin::DirectGoPlugin)
  end

  describe ".go_plugin_type" do
    it "should be nil by default" do
      expect(subject_class.go_plugin_type).to be_nil
    end

    it "should return assigned type when set" do
      subject_class.go_plugin_type = "provider"
      expect(subject_class.go_plugin_type).to eq("provider")
    end
  end

  describe ".go_plugin_type=" do
    it "should allow setting plugin type" do
      subject_class.go_plugin_type = "test_type"
      expect(subject_class.go_plugin_type).to eq("test_type")
    end

    it "should convert plugin type value to string" do
      subject_class.go_plugin_type = :test_type
      expect(subject_class.go_plugin_type).to eq("test_type")
    end

    it "should raise an error when type has already been set" do
      subject_class.go_plugin_type = :test_type
      expect {
        subject_class.go_plugin_type = :different_type
      }.to raise_error(ArgumentError)
    end
  end

  describe "#plugin_type" do
    it "should proxy to .go_plugin_type" do
      expect(subject_class).to receive(:go_plugin_type)
      subject.plugin_type
    end
  end
end
