require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/config")

describe VagrantPlugins::ProviderVirtualBox::Config do
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

  def valid_defaults
    subject.image = "foo"
  end

  before do
    vm_config = double("vm_config")
    allow(vm_config).to receive(:networks).and_return([])
    config = double("config")
    allow(config).to receive(:vm).and_return(vm_config)
    allow(machine).to receive(:config).and_return(config)
  end

  its "valid by default" do
    subject.finalize!
    assert_valid
  end

  context "defaults" do
    before { subject.finalize! }

    it { expect(subject.check_guest_additions).to be(true) }
    it { expect(subject.gui).to be(false) }
    it { expect(subject.name).to be_nil }
    it { expect(subject.functional_vboxsf).to be(true) }

    it "should have one NAT adapter" do
      expect(subject.network_adapters).to eql({
        1 => [:nat, {}],
      })
    end
  end

  describe "#merge" do
    let(:one) { described_class.new }
    let(:two) { described_class.new }

    subject { one.merge(two) }

    it "merges the customizations" do
      one.customize ["foo"]
      two.customize ["bar"]

      expect(subject.customizations).to eq([
        ["pre-boot", ["foo"]],
        ["pre-boot", ["bar"]]])
    end
  end

  describe "#network_adapter" do
    it "configures additional adapters" do
      subject.network_adapter(2, :bridged, auto_config: true)
      expect(subject.network_adapters[2]).to eql(
        [:bridged, auto_config: true])
    end
  end
end
