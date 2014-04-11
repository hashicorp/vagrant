require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/providers/docker/config")

describe VagrantPlugins::DockerProvider::Config do
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

  describe "defaults" do
    before { subject.finalize! }

    its(:cmd) { should eq([]) }
    its(:image) { should be_nil }
    its(:privileged) { should be_false }
    its(:vagrant_machine) { should be_nil }
    its(:vagrant_vagrantfile) { should be_nil }
  end

  before do
    # By default lets be Linux for validations
    Vagrant::Util::Platform.stub(linux: true)
  end

  it "should be valid by default" do
    subject.finalize!
    assert_valid
  end
end
