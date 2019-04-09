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
end
