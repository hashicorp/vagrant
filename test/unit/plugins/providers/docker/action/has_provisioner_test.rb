require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/has_provisioner"


describe VagrantPlugins::DockerProvider::Action::HasProvisioner do
  include_context "unit"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:provisioner_one) { double("provisioner_one") }
  let(:provisioner_two) { double("provisioner_two") }
  let(:provisioners) { [provisioner_one, provisioner_two] }

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :docker).tap do |m|
      allow(m).to receive_message_chain(:config, :vm, :provisioners).and_return(provisioners)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new(".") }}
  let(:app)    { lambda { |*args| }}

  subject { described_class.new(app, env) }

  after do
    sandbox.close
  end

  describe "#call" do

    before do 
      allow(provisioner_one).to receive(:communicator_required).and_return(true)
      allow(provisioner_two).to receive(:communicator_required).and_return(false)
    end

    it "does not skip any provisioners if provider has ssh" do
      env[:machine].provider_config.has_ssh = true
      expect(provisioner_one).to_not receive(:communicator_required)
      expect(provisioner_two).to_not receive(:communicator_required)
      
      subject.call(env)
      expect(env[:skip]).to eq([])
    end

    it "skips provisioners that require a communicator if provider does not have ssh" do
      env[:machine].provider_config.has_ssh = false
      expect(provisioner_one).to receive(:communicator_required)
      expect(provisioner_two).to receive(:communicator_required)
      expect(provisioner_one).to receive(:run=).with(:never)
     
      subject.call(env)
      expect(env[:skip]).to eq([provisioner_one])
    end

  end
end
