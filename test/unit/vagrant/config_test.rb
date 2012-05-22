require File.expand_path("../../base", __FILE__)

describe Vagrant::Config do
  it "should not execute the proc on configuration" do
    described_class.run do
      raise Exception, "Failure."
    end
  end

  it "should capture calls to `Vagrant.configure`" do
    receiver = double()

    procs = described_class.capture_configures do
      Vagrant.configure("1") do
        receiver.one
      end

      Vagrant.configure("2") do
        receiver.two
      end
    end

    procs.should be_kind_of(Array)
    procs.length.should == 2
    procs[0][0].should == "1"
    procs[1][0].should == "2"

    # Verify the proper procs were captured
    receiver.should_receive(:one).once.ordered
    receiver.should_receive(:two).once.ordered
    procs[0][1].call
    procs[1][1].call
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
    procs[0][0].should == "1"
    procs[0][1].call
  end

  it "should capture the proper version" do
    procs = described_class.capture_configures do
      described_class.run("1") {}
      described_class.run("2") {}
    end

    # Verify the structure of the result
    procs.should be_kind_of(Array)
    procs.length.should == 2
    procs[0][0].should == "1"
    procs[1][0].should == "2"
  end
end
