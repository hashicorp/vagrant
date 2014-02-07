require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Action::PrepareNFSValidIds do
  include_context "virtualbox"

  let(:machine) {
    environment                    = Vagrant::Environment.new
    provider                       = :virtualbox
    provider_cls, provider_options = Vagrant.plugin("2").manager.providers[provider]
    provider_config                = Vagrant.plugin("2").manager.provider_configs[provider]

    Vagrant::Machine.new(
      'test_machine',
      provider,
      provider_cls,
      provider_config,
      provider_options,
      environment.vagrantfile.config,
      Pathname('data_dir'),
      double('box'),
      environment
    )
  }

  let(:env)    {{ machine: machine }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { env[:machine].provider.driver }

  subject { described_class.new(app, env) }

  before do
    driver.stub(read_vms: {})
  end

  it "calls the next action in the chain" do
    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    called.should == true
  end

  it "sets nfs_valid_ids" do
    hash = {"foo" => "1", "bar" => "4"}
    driver.stub(read_vms: hash)

    subject.call(env)

    expect(env[:nfs_valid_ids]).to eql(hash.values)
  end
end
