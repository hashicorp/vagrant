require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Step do
  describe "call_enter" do
    it "calls enter with inputs and returns the outputs" do
      step_class = Class.new(described_class) do
        input  :in
        output :out

        def enter
          return :out => @in * 2
        end
      end

      step_class.new.call_enter(:in => 12).should == { :out => 24 }
    end

    it "raises an exception if not all required parameters are given" do
      step_class = Class.new(described_class) do
        input :foo
      end

      expect { step_class.new.call_enter }.to raise_error(Vagrant::Action::Step::UnsatisfiedRequirementsError)
    end

    it "return an empty hash if no outputs are specified" do
      step_class = Class.new(described_class) do
        def enter
          return 12
        end
      end

      step_class.new.call_enter.should == {}
    end

    it "raises an exception if missing outputs" do
      step_class = Class.new(described_class) do
        output :foo

        def enter
          return :bar => 12
        end
      end

      expect { step_class.new.call_enter }.to raise_error(RuntimeError)
    end
  end

  describe "call_exit" do
    it "should simply call the `exit` method with the given argument" do
      step_class = Class.new(described_class) do
        def exit(error)
          raise RuntimeError, error
        end
      end

      expect { step_class.new.call_exit(7) }.to raise_error(RuntimeError)
    end
  end

  describe "calling" do
    it "calls enter then exit" do
      step_class = Class.new(described_class) do
        input :obj

        def enter
          @obj << "enter"
        end

        def exit(error)
          @obj << "exit"
        end
      end

      obj = []
      step_class.new.call(:obj => obj)
      obj.should == ["enter", "exit"]
    end

    it "calls exit with nil if no exception occurred" do
      step_class = Class.new(described_class) do
        input :obj

        def exit(error)
          @obj << error
        end
      end

      obj = []
      step_class.new.call(:obj => obj)
      obj.should == [nil]
    end

    it "calls exit with an exception if it occurred" do
      step_class = Class.new(described_class) do
        input :obj

        def enter
          raise RuntimeError, "foo"
        end

        def exit(error)
          @obj << error
        end
      end

      obj = []
      expect { step_class.new.call(:obj => obj) }.to raise_error(RuntimeError)
      obj[0].should be_kind_of(RuntimeError)
    end
  end
end
