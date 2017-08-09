require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe VagrantPlugins::Kernel_V2::VMConfig do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.values.any? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.values.all? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  def find_network(name)
    network_definitions = subject.networks.map do |n|
      n[1]
    end
    network_definitions.find {|n| n[:id] == name}
  end

  before do
    env = double("env")
    allow(env).to receive(:root_path).and_return(nil)
    allow(machine).to receive(:env).and_return(env)
    allow(machine).to receive(:provider_config).and_return(nil)
    allow(machine).to receive(:provider_options).and_return({})

    subject.box = "foo"
  end

  it "is valid with test defaults" do
    subject.finalize!
    assert_valid
  end

  describe "#base_mac" do
    it "defaults properly" do
      subject.finalize!
      expect(subject.base_mac).to be_nil
    end
  end

  describe "#box" do
    it "is required" do
      subject.box = nil
      subject.finalize!
      assert_invalid
    end

    it "is not required if the provider says so" do
      machine.provider_options[:box_optional] = true
      subject.box = nil
      subject.finalize!
      assert_valid
    end

    it "is invalid if clone is set" do
      subject.clone = "foo"
      subject.finalize!
      assert_invalid
    end
  end

  context "#box_check_update" do
    it "defaults to true" do
      with_temp_env("VAGRANT_BOX_UPDATE_CHECK_DISABLE" => "") do
        subject.finalize!
        expect(subject.box_check_update).to be(true)
      end
    end

    it "is false if VAGRANT_BOX_UPDATE_CHECK_DISABLE is set" do
      with_temp_env("VAGRANT_BOX_UPDATE_CHECK_DISABLE" => "1") do
        subject.finalize!
        expect(subject.box_check_update).to be(false)
      end
    end
  end

  describe "#box_url" do
    it "defaults to nil" do
      subject.finalize!

      expect(subject.box_url).to be_nil
    end

    it "turns into an array" do
      subject.box_url = "foo"
      subject.finalize!

      expect(subject.box_url).to eq(
        ["foo"])
    end

    it "keeps in array" do
      subject.box_url = ["foo", "bar"]
      subject.finalize!

      expect(subject.box_url).to eq(
        ["foo", "bar"])
    end
  end

  context "#box_version" do
    it "defaults to nil" do
      subject.finalize!

      expect(subject.box_version).to be_nil
    end

    it "errors if invalid version" do
      subject.box_version = "nope"
      subject.finalize!

      expect { assert_valid }.to raise_error(RuntimeError)
    end

    it "can have complex constraints" do
      subject.box_version = ">= 0, ~> 1.0"
      subject.finalize!

      assert_valid
    end

    ["1", 1, "1.0", 1.0].each do |valid|
      it "is valid: #{valid}" do
        subject.box_version = valid
        subject.finalize!
        assert_valid
      end
    end
  end

  describe "#communicator" do
    it "is nil by default" do
      subject.finalize!
      expect(subject.communicator).to be_nil
    end
  end

  describe "#guest" do
    it "is nil by default" do
      subject.finalize!
      expect(subject.guest).to be_nil
    end

    it "is symbolized" do
      subject.guest = "foo"
      subject.finalize!
      expect(subject.guest).to eq(:foo)
    end
  end

  describe "#hostname" do
    ["a", "foo", "foo-bar", "baz0"].each do |valid|
      it "is valid: #{valid}" do
        subject.hostname = valid
        subject.finalize!
        assert_valid
      end
    end
  end

  describe "#network(s)" do
    it "defaults to forwarding SSH by default" do
      subject.finalize!
      n = subject.networks
      expect(n.length).to eq(1)
      expect(n[0][0]).to eq(:forwarded_port)
      expect(n[0][1][:guest]).to eq(22)
      expect(n[0][1][:host]).to eq(2222)
      expect(n[0][1][:host_ip]).to eq("127.0.0.1")
      expect(n[0][1][:id]).to eq("ssh")
    end

    it "defaults to forwarding WinRM if communicator is winrm" do
      subject.communicator = "winrm"
      subject.finalize!
      n = subject.networks
      expect(n.length).to eq(3)

      expect(n[0][0]).to eq(:forwarded_port)
      expect(n[0][1][:guest]).to eq(5985)
      expect(n[0][1][:host]).to eq(55985)
      expect(n[0][1][:host_ip]).to eq("127.0.0.1")
      expect(n[0][1][:id]).to eq("winrm")

      expect(n[1][0]).to eq(:forwarded_port)
      expect(n[1][1][:guest]).to eq(5986)
      expect(n[1][1][:host]).to eq(55986)
      expect(n[1][1][:host_ip]).to eq("127.0.0.1")
      expect(n[1][1][:id]).to eq("winrm-ssl")
    end

    it "forwards ssh even if the communicator is winrm" do
      subject.communicator = "winrm"
      subject.finalize!
      n = subject.networks
      expect(n.length).to eq(3)

      expect(n[0][0]).to eq(:forwarded_port)
      expect(n[0][1][:guest]).to eq(5985)
      expect(n[0][1][:host]).to eq(55985)
      expect(n[0][1][:host_ip]).to eq("127.0.0.1")
      expect(n[0][1][:id]).to eq("winrm")

      expect(n[1][0]).to eq(:forwarded_port)
      expect(n[1][1][:guest]).to eq(5986)
      expect(n[1][1][:host]).to eq(55986)
      expect(n[1][1][:host_ip]).to eq("127.0.0.1")
      expect(n[1][1][:id]).to eq("winrm-ssl")

      expect(n[2][0]).to eq(:forwarded_port)
      expect(n[2][1][:guest]).to eq(22)
      expect(n[2][1][:host]).to eq(2222)
      expect(n[2][1][:host_ip]).to eq("127.0.0.1")
      expect(n[2][1][:id]).to eq("ssh")

    end

    it "allows overriding SSH" do
      subject.network "forwarded_port",
        guest: 22, host: 14100, id: "ssh"
      subject.finalize!

      n = subject.networks
      expect(n.length).to eq(1)
      expect(n[0][0]).to eq(:forwarded_port)
      expect(n[0][1][:guest]).to eq(22)
      expect(n[0][1][:host]).to eq(14100)
      expect(n[0][1][:id]).to eq("ssh")
    end

    it "allows overriding WinRM" do
      subject.communicator = :winrm
      subject.network "forwarded_port",
        guest: 5985, host: 14100, id: "winrm"
      subject.finalize!

      winrm_network = find_network 'winrm'
      expect(winrm_network[:guest]).to eq(5985)
      expect(winrm_network[:host]).to eq(14100)
      expect(winrm_network[:id]).to eq("winrm")
    end

    it "allows overriding WinRM SSL" do
      subject.communicator = :winrm
      subject.network "forwarded_port",
        guest: 5986, host: 14100, id: "winrm-ssl"
      subject.finalize!

      winrmssl_network = find_network 'winrm-ssl'
      expect(winrmssl_network[:guest]).to eq(5986)
      expect(winrmssl_network[:host]).to eq(14100)
      expect(winrmssl_network[:id]).to eq("winrm-ssl")
    end

    it "turns all forwarded port ports to ints" do
      subject.network "forwarded_port",
        guest: "45", host: "4545", id: "test"
      subject.finalize!
      n = subject.networks.find do |type, data|
        type == :forwarded_port && data[:id] == "test"
      end
      expect(n).to_not be_nil
      expect(n[1][:guest]).to eq(45)
      expect(n[1][:host]).to eq(4545)
    end

    it "is an error if forwarding a port too low" do
      subject.network "forwarded_port",
        guest: "45", host: "-5"
      subject.finalize!
      assert_invalid
    end

    it "is an error if forwarding a port too high" do
      subject.network "forwarded_port",
        guest: "45", host: "74545"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#post_up_message" do
    it "defaults to empty string" do
      subject.finalize!
      expect(subject.post_up_message).to eq("")
    end

    it "can be set" do
      subject.post_up_message = "foo"
      subject.finalize!
      expect(subject.post_up_message).to eq("foo")
    end
  end

  describe "#provider and #__providers" do
    it "returns the providers in order" do
      subject.provider "foo"
      subject.provider "bar"
      subject.finalize!

      expect(subject.__providers).to eq([:foo, :bar])
    end

    describe "merging" do
      it "prioritizes new orders in later configs" do
        subject.provider "foo"

        other = described_class.new
        other.provider "bar"

        merged = subject.merge(other)

        expect(merged.__providers).to eq([:foo, :bar])
      end

      it "prioritizes duplicates in new orders in later configs" do
        subject.provider "foo"

        other = described_class.new
        other.provider "bar"
        other.provider "foo"

        merged = subject.merge(other)

        expect(merged.__providers).to eq([:foo, :bar])
      end
    end
  end

  describe "#provider and #get_provider_config" do
    it "compiles the configurations for a provider" do
      subject.provider "virtualbox" do |vb|
        vb.gui = true
      end

      subject.provider "virtualbox" do |vb|
        vb.name = "foo"
      end

      subject.finalize!

      config = subject.get_provider_config(:virtualbox)
      expect(config.name).to eq("foo")
      expect(config.gui).to be(true)
    end

    it "raises an exception if there is a problem loading" do
      subject.provider "virtualbox" do |vb|
        # Purposeful bad variable
        vm.foo = "bar"
      end

      expect { subject.finalize! }.
        to raise_error(Vagrant::Errors::VagrantfileLoadError)
    end
  end

  describe "#provision" do
    it "stores the provisioners" do
      subject.provision("shell", inline: "foo")
      subject.provision("shell", inline: "bar", run: "always") { |s| s.path = "baz" }
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(2)
      expect(r[0].run).to be_nil
      expect(r[0].config.inline).to eql("foo")
      expect(r[1].config.inline).to eql("bar")
      expect(r[1].config.path).to eql("baz")
      expect(r[1].run).to eql(:always)
    end

    it "allows provisioner settings to be overriden" do
      subject.provision("s", path: "foo", type: "shell") { |s| s.inline = "foo" }
      subject.provision("s", inline: "bar", type: "shell") { |s| s.args = "bar" }
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(1)
      expect(r[0].config.args).to eql("bar")
      expect(r[0].config.inline).to eql("bar")
      expect(r[0].config.path).to eql("foo")
    end

    it "marks as invalid if a bad name" do
      subject.provision("nope", inline: "foo")
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(1)
      expect(r[0]).to be_invalid
    end

    it "allows provisioners that don't define any config" do
      register_plugin("2") do |p|
        p.name "foo"
        # This plugin registers a dummy provisioner
        # without registering a provisioner config
        p.provisioner(:foo) do
          Class.new Vagrant::plugin("2", :provisioner)
        end
      end

      subject.provision("foo") do |c|
        c.bar = "baz"
      end

      # This should succeed without errors
      expect{ subject.finalize! }.to_not raise_error
    end

    it "generates a uuid if no name was provided" do
      allow(SecureRandom).to receive(:uuid).and_return("MY_CUSTOM_VALUE")

      subject.provision("shell", path: "foo") { |s| s.inline = "foo" }
      subject.finalize!

      r = subject.provisioners
      expect(r[0].id).to eq("MY_CUSTOM_VALUE")
    end

    it "sets id as name if a name was provided" do
      subject.provision("ghost", type: "shell", path: "motoko") { |s| s.inline = "motoko" }
      subject.finalize!

      r = subject.provisioners
      expect(r[0].id).to eq(:ghost)
    end

    describe "merging" do
      it "ignores non-overriding runs" do
        subject.provision("shell", inline: "foo", run: "once")

        other = described_class.new
        other.provision("shell", inline: "bar", run: "always")

        merged = subject.merge(other)
        merged_provs = merged.provisioners

        expect(merged_provs.length).to eql(2)
        expect(merged_provs[0].run).to eq("once")
        expect(merged_provs[1].run).to eq("always")
      end

      it "does not merge duplicate provisioners" do
        subject.provision("shell", inline: "foo")
        subject.provision("shell", inline: "bar")

        merged = subject.merge(subject)
        merged_provs = merged.provisioners

        expect(merged_provs.length).to eql(2)
      end

      it "copies the configs" do
        subject.provision("shell", inline: "foo")
        subject_provs = subject.provisioners

        other = described_class.new
        other.provision("shell", inline: "bar")

        merged = subject.merge(other)
        merged_provs = merged.provisioners

        expect(merged_provs.length).to eql(2)
        expect(merged_provs[0].config.inline).
          to eq(subject_provs[0].config.inline)
        expect(merged_provs[0].config.object_id).
          to_not eq(subject_provs[0].config.object_id)
      end

      it "uses the proper order when merging overrides" do
        subject.provision("original", inline: "foo", type: "shell")
        subject.provision("other", inline: "other", type: "shell")

        other = described_class.new
        other.provision("shell", inline: "bar")
        other.provision("original", inline: "foo-overload", type: "shell")

        merged = subject.merge(other)
        merged_provs = merged.provisioners

        expect(merged_provs.length).to eql(3)
        expect(merged_provs[0].config.inline).
          to eq("other")
        expect(merged_provs[1].config.inline).
          to eq("bar")
        expect(merged_provs[2].config.inline).
          to eq("foo-overload")
      end

      it "can preserve order for overrides" do
        subject.provision("original", inline: "foo", type: "shell")
        subject.provision("other", inline: "other", type: "shell")

        other = described_class.new
        other.provision("shell", inline: "bar")
        other.provision(
          "original", inline: "foo-overload", type: "shell",
          preserve_order: true)

        merged = subject.merge(other)
        merged_provs = merged.provisioners

        expect(merged_provs.length).to eql(3)
        expect(merged_provs[0].config.inline).
          to eq("foo-overload")
        expect(merged_provs[1].config.inline).
          to eq("other")
        expect(merged_provs[2].config.inline).
          to eq("bar")
      end
    end
  end

  describe "#synced_folder(s)" do
    it "defaults to sharing the current directory" do
      subject.finalize!
      sf = subject.synced_folders
      expect(sf.length).to eq(1)
      expect(sf).to have_key("/vagrant")
      expect(sf["/vagrant"][:disabled]).to_not be
    end

    it "allows overriding settings on the /vagrant sf" do
      subject.synced_folder(".", "/vagrant", disabled: true)
      subject.finalize!
      sf = subject.synced_folders
      expect(sf.length).to eq(1)
      expect(sf).to have_key("/vagrant")
      expect(sf["/vagrant"][:disabled]).to be(true)
    end

    it "allows overriding previously set options" do
      subject.synced_folder(".", "/vagrant", disabled: true)
      subject.synced_folder(".", "/vagrant", foo: :bar)
      subject.finalize!
      sf = subject.synced_folders
      expect(sf.length).to eq(1)
      expect(sf).to have_key("/vagrant")
      expect(sf["/vagrant"][:disabled]).to be(false)
      expect(sf["/vagrant"][:foo]).to eq(:bar)
    end

    it "is not an error if guest path is empty" do
      subject.synced_folder(".", "")
      subject.finalize!
      assert_valid
    end

    it "allows providing custom name via options" do
      subject.synced_folder(".", "/vagrant", name: "my-vagrant-folder")
      sf = subject.synced_folders
      expect(sf).to have_key("my-vagrant-folder")
      expect(sf["my-vagrant-folder"][:guestpath]).to eq("/vagrant")
      expect(sf["my-vagrant-folder"][:hostpath]).to eq(".")
    end

    it "allows providing custom name without guest path" do
      subject.synced_folder(".", name: "my-vagrant-folder")
      sf = subject.synced_folders
      expect(sf).to have_key("my-vagrant-folder")
      expect(sf["my-vagrant-folder"][:hostpath]).to eq(".")
    end
  end

  describe "#usable_port_range" do
    it "defaults properly" do
      subject.finalize!
      expect(subject.usable_port_range).to eq(
        Range.new(2200, 2250))
    end
  end
end
