require File.expand_path("../../base", __FILE__)

describe Vagrant::Box do
  let(:name)          { "foo" }
  let(:directory)     { "bar" }
  let(:action_runner) { double("action_runner") }
  let(:instance)      { described_class.new(name, directory, action_runner) }

  it "provides the name" do
    instance.name.should == name
  end

  it "can destroy itself" do
    # Simply test the messages to the action runner
    options = {
      :box_name => name,
      :box_directory => directory
    }
    action_runner.should_receive(:run).with(:box_remove, options)

    instance.destroy
  end
end
