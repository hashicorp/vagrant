require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/disk")

describe VagrantPlugins::Kernel_V2::VagrantConfigDisk do
  include_context "unit"

  let(:type) { :disk }

  subject { described_class.new(type) }

  let(:machine) { double("machine") }

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.empty? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.empty? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  before do
    env = double("env")

    subject.name = "foo"
    subject.size = 100
  end

  describe "with defaults" do
    it "is valid with test defaults" do
      subject.finalize!
      assert_valid
    end

    it "sets a disk type" do
      subject.finalize!
      expect(subject.type).to eq(type)
    end

    it "defaults to non-primray disk" do
      subject.finalize!
      expect(subject.primary).to eq(false)
    end
  end

  describe "defining a new config that needs to match internal restraints" do
    before do
    end
  end
end
