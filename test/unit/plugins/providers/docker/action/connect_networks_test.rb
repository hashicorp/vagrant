require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/connect_networks"

describe VagrantPlugins::DockerProvider::Action::ConnectNetworks do
  include_context "unit"
  include_context "virtualbox"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :docker).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m.config.vm).to receive(:networks).and_return(networks)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new(".") }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver", create: "abcd1234") }

  let(:networks) { [[:private_network,
          {:ip=>"172.20.128.2",
           :subnet=>"172.20.0.0/16",
           :driver=>"bridge",
           :internal=>"true",
           :alias=>"mynetwork",
           :protocol=>"tcp",
           :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"}],
         [:private_network,
          {:type=>"dhcp",
           :ipv6=>"true",
           :subnet=>"2a02:6b8:b010:9020:1::/80",
           :protocol=>"tcp",
           :id=>"b8f23054-38d5-45c3-99ea-d33fc5d1b9f2"}],
         [:forwarded_port,
          {:guest=>22, :host=>2200, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]]
  }

  let(:invalid_network) {
         [[:private_network,
          {:ipv6=>"true",
           :protocol=>"tcp",
           :id=>"b8f23054-38d5-45c3-99ea-d33fc5d1b9f2"}]]
        }

  subject { described_class.new(app, env) }

  after do
    sandbox.close
  end

  describe "#call" do
    it "calls the next action in the chain" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(false)
      allow(driver).to receive(:create_network).and_return(true)
      allow(driver).to receive(:connect_network).and_return(true)
      allow(driver).to receive(:subnet_defined?).and_return(nil)

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)
      action.call(env)

      expect(called).to eq(true)
    end

    it "calls the proper driver methods to setup a network" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(false)
      allow(driver).to receive(:create_network).and_return(true)
      allow(driver).to receive(:connect_network).and_return(true)
      allow(driver).to receive(:subnet_defined?).and_return(nil)


      expect(subject).to receive(:generate_create_cli_arguments).
        with(networks[0][1]).and_return(["--subnet=172.20.0.0/16", "--driver=bridge", "--internal=true"])
      expect(subject).to receive(:generate_create_cli_arguments).
        with(networks[1][1]).and_return(["--ipv6=true", "--subnet=2a02:6b8:b010:9020:1::/80"])
      expect(subject).to receive(:generate_connect_cli_arguments).
        with(networks[0][1]).and_return(["--ipv6=true", "--subnet=2a02:6b8:b010:9020:1::/80"])
      expect(subject).to receive(:generate_connect_cli_arguments).
        with(networks[1][1]).and_return([])

      expect(driver).to receive(:create_network).twice
      expect(driver).to receive(:connect_network).twice

      subject.call(env)
    end

    it "uses an existing network if a matching subnet is found" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(true)
      allow(driver).to receive(:create_network).and_return(true)
      allow(driver).to receive(:connect_network).and_return(true)
      allow(driver).to receive(:subnet_defined?).and_return("my_cool_subnet_network")

      expect(driver).not_to receive(:create_network)

      subject.call(env)
    end

    it "raises an error if an inproper network configuration is given" do
      allow(machine.config.vm).to receive(:networks).and_return(invalid_network)
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(false)

      expect{ subject.call(env) }.to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkInvalidOption)
    end
  end

  describe "#generate_connect_cli_arguments" do
    let(:network_options) {
            {:ip=>"172.20.128.2",
             :subnet=>"172.20.0.0/16",
             :driver=>"bridge",
             :internal=>"true",
             :alias=>"mynetwork",
             :protocol=>"tcp",
             :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"} }

    it "returns an array of cli arguments" do
      cli_args = subject.generate_connect_cli_arguments(network_options)
      expect(cli_args).to eq(["--ip", "172.20.128.2", "--alias=mynetwork"])
    end
  end

  describe "#generate_create_cli_arguments" do
    let(:network_options) {
            {:ip=>"172.20.128.2",
             :subnet=>"172.20.0.0/16",
             :driver=>"bridge",
             :internal=>"true",
             :alias=>"mynetwork",
             :protocol=>"tcp",
             :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"} }

    it "returns an array of cli arguments" do
      cli_args = subject.generate_create_cli_arguments(network_options)
      expect(cli_args).to eq(["--subnet=172.20.0.0/16", "--driver=bridge", "--internal=true"])
    end
  end
end
