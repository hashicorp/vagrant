require 'thread'
require 'timeout'

require File.expand_path("../../base", __FILE__)

describe Vagrant::BatchAction do
  let(:called_actions) { [] }
  let!(:lock) { Mutex.new }
  let(:provider_name) { "test" }
  let(:provider_options) { {} }

  def new_machine(options)
    double("machine").tap do |m|
      m.stub(provider_name: provider_name)
      m.stub(provider_options: options)
      allow(m).to receive(:action) do |action, opts|
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

      expect(called_actions.include?([machine, "up", nil])).to be
      expect(called_actions.include?([machine2, "destroy", nil])).to be
    end

    it "should run the arbitrary methods in order" do
      called = []
      subject.custom(machine)  { |m| called << m }
      subject.custom(machine2) { |m| called << m }
      subject.run

      expect(called[0]).to equal(machine)
      expect(called[1]).to equal(machine2)
    end

    it "should handle forks gracefully", :skip_windows do
      # Doesn't need to be tested on Windows since Windows doesn't
      # support fork(1)
      allow(machine).to receive(:action) do |action, opts|
        pid = fork
        if !pid
          # Child process
          exit
        end

        # Parent process, wait for the child to exit
        Timeout.timeout(1) do
          Process.waitpid(pid)
        end
      end

      subject.action(machine, "up")
      subject.run
    end
  end
end
