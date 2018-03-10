require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm_trigger")

describe VagrantPlugins::Kernel_V2::VagrantConfigTrigger do
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

  before do
    env = double("env")
    allow(env).to receive(:root_path).and_return(nil)
    allow(machine).to receive(:env).and_return(env)
    allow(machine).to receive(:provider_config).and_return(nil)
    allow(machine).to receive(:provider_options).and_return({})

    subject.name = "foo"
  end

  it "is valid with test defaults" do
    subject.finalize!
    assert_valid
  end
end
