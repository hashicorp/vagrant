require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Provider do
  include_context "unit"

  let(:machine)  { Object.new }
  let(:instance) { described_class.new(machine) }

  subject { instance }

  it "should be usable by default" do
    expect(described_class).to be_usable
  end

  it "should be installed by default" do
    expect(described_class).to be_installed
  end

  it "should return nil by default for actions" do
    expect(instance.action(:whatever)).to be_nil
  end

  it "should return nil by default for ssh info" do
    expect(instance.ssh_info).to be_nil
  end

  it "should return nil by default for state" do
    expect(instance.state).to be_nil
  end

  context "capabilities" do
    before do
      register_plugin("2") do |p|
        p.provider_capability("bar", "foo") {}

        p.provider_capability("foo", "bar") do
          Class.new do
            def self.bar(machine)
              raise "bar #{machine.id}"
            end
          end
        end
      end

      allow(machine).to receive(:id).and_return("YEAH")

      instance._initialize("foo", machine)
    end

    it "can execute capabilities" do
      expect(subject.capability?(:foo)).to be(false)
      expect(subject.capability?(:bar)).to be(true)

      expect { subject.capability(:bar) }.
        to raise_error("bar YEAH")
    end
  end
end
