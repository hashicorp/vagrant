require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Step do
  it "provides the parameters as instance variables" do
    step_class = Class.new(described_class) do
      input :foo

      def execute
        return :value => @foo
      end
    end

    step_class.new.call(:foo => 12).should == { :value => 12 }
  end

  it "raises an exception if not all required parameters are given" do
    step_class = Class.new(described_class) do
      input :foo
    end

    expect { step_class.new.call }.to raise_error(ArgumentError)
  end

  it "calls a custom method if given" do
    step_class = Class.new(described_class) do
      def prepare
        return :foo => 12
      end
    end

    step_class.new.call({}, :method => :prepare).should == { :foo => 12 }
  end

  describe "outputs" do
    it "return an empty hash if no outputs are specified" do
      step_class = Class.new(described_class) do
        def execute
          return 12
        end
      end

      step_class.new.call.should == {}
    end

    it "raises an exception if missing outputs" do
      step_class = Class.new(described_class) do
        output :foo

        def execute
          return :bar => 12
        end
      end

      expect { step_class.new.call }.to raise_error(RuntimeError)
    end

    it "does nothing if missing outputs but we disabled validating" do
      step_class = Class.new(described_class) do
        output :foo

        def execute
          return :bar => 12
        end
      end

      step_class.new.call({}, :validate_output => false).should == { :bar => 12 }
    end
  end
end
