require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::MultiStep do
  it "should compose a series of steps" do
    step_A = Class.new(Vagrant::Action::Step) do
      input  :obj
      output :obj

      def enter
        @obj << "A"
        return :obj => @obj
      end
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input  :obj
      output :result

      def enter
        return :result => (@obj << "B")
      end
    end

    obj = []

    ms = described_class.new
    ms.step step_A
    ms.step step_B
    ms.call(:obj => obj).should == { :result => ["A", "B"] }
  end

  it "should allow for custom inputs to pass to specific steps" do
    step_A = Class.new(Vagrant::Action::Step) do
      def enter
        # Do nothing.
      end
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input :obj

      def enter
        @obj << "B"
      end
    end

    obj = []

    ms = described_class.new
    ms.step step_A
    ms.step step_B, :obj
    ms.call(:obj => obj)

    obj.should == ["B"]
  end

  it "should be able to remap input names" do
    step_A = Class.new(Vagrant::Action::Step) do
      output :foo

      def enter
        return :foo => "A"
      end
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input  :from
      output :value

      def enter
        return :value => @from
      end
    end

    obj = []

    ms = described_class.new
    ms.step step_A
    ms.step step_B, :foo => :from
    ms.call.should == { :value => "A" }
  end

  it "should be able to reference variables from steps before other steps" do
    step_A = Class.new(Vagrant::Action::Step) do
      output :foo

      def enter
        return :foo => 10
      end
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input  :from
      output :value

      def enter
        return :value => @from
      end
    end

    step_C = Class.new(Vagrant::Action::Step) do
      input  :number
      output :value

      def enter
        return :value => @number * 2
      end
    end

    obj = []

    g = described_class.new
    g.step step_A
    g.step step_B, :foo => :from
    g.step step_C, g.output(step_A, :foo) => :number
    g.call.should == { :value => 20 }
  end

  it "should error if multiple steps of the same class are given without explicit names" do
    step_A = Class.new(Vagrant::Action::Step)

    g = described_class.new
    g.step step_A
    expect { g.step step_A }.to raise_error(NameError)
  end

  it "should not error if multiple steps of the same class are given with custom names" do
    step_A = Class.new(Vagrant::Action::Step)

    g = described_class.new
    g.step step_A
    expect { g.step :another, step_A }.to_not raise_error
  end

  it "should error if a step is not a class" do
    g = described_class.new
    expect { g.step :foo }.to raise_error(ArgumentError)
  end

  it "should not allow a step that doesn't have all inputs satisfied" do
    step_A = Class.new(Vagrant::Action::Step) do
      output :output_A
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input :input_B
    end

    g = described_class.new
    g.step step_A
    expect { g.step step_B }.to raise_error(ArgumentError)
  end

  it "should not allow remapping from outputs that don't exist" do
    step_A = Class.new(Vagrant::Action::Step) do
      output :output_A
    end

    step_B = Class.new(Vagrant::Action::Step) do
      input :input_B
    end

    g = described_class.new
    g.step step_A
    expect { g.step step_B, :output_B => :input_B }.to raise_error(ArgumentError)
  end

  it "should not allow remapping to inputs that don't exist" do
    step_A = Class.new(Vagrant::Action::Step) do
      input :input_A
    end

    g = described_class.new
    expect { g.step step_A, g.input(:foo) => :input_B }.to raise_error(ArgumentError)
  end

  it "should call the enter methods in order, and the exit in reverse order" do
    step = Class.new(Vagrant::Action::Step) do
      input  :key
      input  :data
      output :data

      def enter
        @data << @key
        return :data => @data
      end

      def exit(error)
        @data << @key
      end
    end

    g = described_class.new
    g.step step
    g.step :two, step, g.input(:key2) => :key
    g.step :three, step, g.input(:key3) => :key
    result = g.call(:data => [], :key => "1", :key2 => "2", :key3 => "3")
    result[:data].should == %W[1 2 3 3 2 1]
  end

  it "should halt the steps and call exit with the error if an error occurs" do
    step = Class.new(Vagrant::Action::Step) do
      input  :key
      input  :data
      output :data

      def enter
        @data << @key
        raise Exception, "E" if @data.last == "2"
        return :data => @data
      end

      def exit(error)
        prefix = error ? error.message : ""
        @data << "#{prefix}#{@key}"
      end
    end

    g = described_class.new
    g.step step
    g.step :two, step, g.input(:key2) => :key
    g.step :three, step, g.input(:key3) => :key

    # Run the actual steps
    data = []
    expect do
      result = g.call(:data => data, :key => "1", :key2 => "2", :key3 => "3")
    end.to raise_error(Exception)

    # Verify the result hit the methods in the proper order
    data.should == %W[1 2 E2 E1]
  end
end
