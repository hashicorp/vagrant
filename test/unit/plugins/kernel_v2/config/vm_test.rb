require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe VagrantPlugins::Kernel_V2::VMConfig do
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

  before do
    env = double("env")
    env.stub(root_path: nil)
    machine.stub(env: env)
    machine.stub(provider_config: nil)

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

  context "#box_check_update" do
    it "defaults to true" do
      subject.finalize!

      expect(subject.box_check_update).to be_true
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
    it "defaults to >= 0" do
      subject.finalize!

      expect(subject.box_version).to eq(">= 0")
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

  describe "#network(s)" do
    it "defaults to forwarding SSH" do
      subject.finalize!
      n = subject.networks
      expect(n.length).to eq(1)
      expect(n[0][0]).to eq(:forwarded_port)
      expect(n[0][1][:guest]).to eq(22)
      expect(n[0][1][:host]).to eq(2222)
      expect(n[0][1][:host_ip]).to eq("127.0.0.1")
      expect(n[0][1][:id]).to eq("ssh")
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
      expect(config.gui).to be_true
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
      subject.provision("shell", inline: "bar") { |s| s.path = "baz" }
      subject.finalize!

      r = subject.provisioners
      expect(r.length).to eql(2)
      expect(r[0].config.inline).to eql("foo")
      expect(r[1].config.inline).to eql("bar")
      expect(r[1].config.path).to eql("baz")
    end

    it "allows provisioner settings to be overriden" do
      subject.provision("shell", path: "foo", id: "s") { |s| s.inline = "foo" }
      subject.provision("shell", inline: "bar", id: "s") { |s| s.args = "bar" }
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

    describe "merging" do
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
        subject.provision("shell", inline: "foo", id: "original")
        subject.provision("shell", inline: "other", id: "other")

        other = described_class.new
        other.provision("shell", inline: "bar")
        other.provision("shell", inline: "foo-overload", id: "original")

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
        subject.provision("shell", inline: "foo", id: "original")
        subject.provision("shell", inline: "other", id: "other")

        other = described_class.new
        other.provision("shell", inline: "bar")
        other.provision(
          "shell", inline: "foo-overload", id: "original",
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
      expect(sf["/vagrant"][:disabled]).to be_true
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
