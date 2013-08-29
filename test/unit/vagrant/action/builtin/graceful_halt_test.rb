require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::GracefulHalt do
  let(:app) { lambda { |env| } }
  let(:env) { { :machine => machine, :ui => ui } }
  let(:machine) do
    result = double("machine")
    result.stub(:config).and_return(machine_config)
    result.stub(:guest).and_return(machine_guest)
    result.stub(:state).and_return(machine_state)
    result
  end
  let(:machine_config) do
    double("machine_config").tap do |top_config|
      vm_config = double("machien_vm_config")
      vm_config.stub(:graceful_halt_timeout => 10)
      top_config.stub(:vm => vm_config)
    end
  end
  let(:machine_guest) { double("machine_guest") }
  let(:machine_state) do
    double("machine_state").tap do |result|
      result.stub(:id).and_return(:unknown)
    end
  end
  let(:target_state) { :target }
  let(:ui) do
    double("ui").tap do |result|
      result.stub(:info)
    end
  end

  it "should do nothing if force is specified" do
    env[:force_halt] = true

    machine_guest.should_not_receive(:capability)

    described_class.new(app, env, target_state).call(env)

    env[:result].should == false
  end

  it "should do nothing if there is an invalid source state" do
    machine_state.stub(:id).and_return(:invalid_source)
    machine_guest.should_not_receive(:capability)

    described_class.new(app, env, target_state, :target_source).call(env)

    env[:result].should == false
  end

  it "should gracefully halt and wait for the target state" do
    machine_guest.should_receive(:capability).with(:halt).once
    machine_state.stub(:id).and_return(target_state)

    described_class.new(app, env, target_state).call(env)

    env[:result].should == true
  end
end
