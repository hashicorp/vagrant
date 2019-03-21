require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/prepare_networks"

describe VagrantPlugins::DockerProvider::Action::PrepareNetworks do
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
           [:public_network,
            {:ip=>"172.30.130.2",
             :subnet=>"172.30.0.0/16",
             :driver=>"bridge",
             :id=>"30e017d5-488f-5a2f-a3ke-k8dce8246b60"}],
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
      allow(driver).to receive(:existing_named_network?).and_return(false)
      allow(driver).to receive(:create_network).and_return(true)

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      allow(action).to receive(:process_public_network).and_return(["name", {}])
      allow(action).to receive(:process_private_network).and_return(["name", {}])

      action.call(env)

      expect(called).to eq(true)
    end

    it "calls the proper driver methods to setup a network" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_named_network?).and_return(false)
      allow(driver).to receive(:network_containing_address).
        with("172.20.128.2").and_return(nil)
      allow(driver).to receive(:network_containing_address).
        with("192.168.1.1").and_return(nil)
      allow(driver).to receive(:network_defined?).with("172.20.128.0/24").
        and_return(false)
      allow(driver).to receive(:network_defined?).with("172.30.128.0/24").
        and_return(false)
      allow(driver).to receive(:network_defined?).with("2a02:6b8:b010:9020:1::/80").
        and_return(false)

      allow(subject).to receive(:request_public_gateway).and_return("1234")
      allow(subject).to receive(:request_public_iprange).and_return("1234")

      allow(machine.ui).to receive(:ask).and_return("1")

      expect(driver).to receive(:create_network).
        with("vagrant_network_172.20.128.0/24", ["--subnet", "172.20.128.0/24"])
      expect(driver).to receive(:create_network).
        with("vagrant_network_public_wlp4s0", ["--opt", "parent=wlp4s0", "--subnet", "192.168.1.0/24", "--driver", "macvlan", "--gateway", "1234", "--ip-range", "1234"])
      expect(driver).to receive(:create_network).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80", ["--ipv6", "--subnet", "2a02:6b8:b010:9020:1::/80"])


      subject.call(env)

      expect(env[:docker_connects]).to eq({0=>"vagrant_network_172.20.128.0/24", 1=>"vagrant_network_public_wlp4s0", 2=>"vagrant_network_2a02:6b8:b010:9020:1::/80"})
    end

    it "uses an existing network if a matching subnet is found" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:network_containing_address).
        with("172.20.128.2").and_return(nil)
      allow(driver).to receive(:network_containing_address).
        with("192.168.1.1").and_return(nil)
      allow(driver).to receive(:network_defined?).with("172.20.128.0/24").
        and_return("vagrant_network_172.20.128.0/24")
      allow(driver).to receive(:network_defined?).with("172.30.128.0/24").
        and_return("vagrant_network_public_wlp4s0")
      allow(driver).to receive(:network_defined?).with("2a02:6b8:b010:9020:1::/80").
        and_return("vagrant_network_2a02:6b8:b010:9020:1::/80")

      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_172.20.128.0/24").and_return(true)
      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_public_wlp4s0").and_return(true)
      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_public_wlp4s0").and_return(true)
      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80").and_return(true)

      allow(machine.ui).to receive(:ask).and_return("1")

      expect(driver).not_to receive(:create_network)

      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_172.20.128.0/24", networks[0][1],
            {:ipv6=>false, :subnet=>"172.20.128.0/24"}, driver)

      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_public_wlp4s0", networks[1][1],
             {"opt"=>"parent=wlp4s0", "subnet"=>"192.168.1.0/24", "driver"=>"macvlan", "gateway"=>"192.168.1.1", "ipv6"=>false}, driver)


      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80", networks[2][1],
            {:ipv6=>true, :subnet=>"2a02:6b8:b010:9020:1::/80"}, driver)

      subject.call(env)

    end

    it "raises an error if an inproper network configuration is given" do
      allow(machine.config.vm).to receive(:networks).and_return(invalid_network)
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(false)

      expect{ subject.call(env) }.to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkIPAddressRequired)
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

    let(:false_network_options) {
            {:ip=>"172.20.128.2",
             :subnet=>"172.20.0.0/16",
             :driver=>"bridge",
             :internal=>"false",
             :alias=>"mynetwork",
             :protocol=>"tcp",
             :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"} }

    it "returns an array of cli arguments" do
      cli_args = subject.generate_create_cli_arguments(network_options)
      expect(cli_args).to eq( ["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--internal", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end

    it "removes option if set to false" do
      cli_args = subject.generate_create_cli_arguments(false_network_options)
      expect(cli_args).to eq( ["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end
  end
end
