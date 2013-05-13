require 'thread'

require File.expand_path("../../base", __FILE__)

describe Vagrant::BatchAction do
  let(:called_actions) { [] }
  let!(:lock) { Mutex.new }
  let(:provider_name) { "test" }
  let(:provider_options) { {} }

  def new_machine(options)
    double("machine").tap do |m|
      m.stub(:provider_name => provider_name)
      m.stub(:provider_options => options)
      m.stub(:action) do |action, opts|
        lock.synchronize do
          called_actions << [m, action, opts]
        end
      end
    end
  end

  describe "#run" do
    let(:machine) { new_machine(provider_options) }
    let(:machine2) { new_machine(provider_options) }

    it "should run the actions on the machines in order" do
      subject.action(machine, "up")
      subject.action(machine2, "destroy")
      subject.run

      called_actions.include?([machine, "up", nil]).should be
      called_actions.include?([machine2, "destroy", nil]).should be
    end
  end
end
