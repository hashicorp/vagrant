require File.expand_path("../../base", __FILE__)

describe Vagrant::Config do
  it "should not execute the proc on configuration" do
    described_class.run do
      raise Exception, "Failure."
    end
  end

  it "should capture configuration procs" do
    receiver = double()

    procs = described_class.capture_configures do
      described_class.run do
        receiver.hello!
      end
    end

    # Verify the structure of the result
    procs.should be_kind_of(Array)
    procs.length.should == 1

    # Verify that the proper proc was captured
    receiver.should_receive(:hello!).once
    procs[0].call
  end
end
