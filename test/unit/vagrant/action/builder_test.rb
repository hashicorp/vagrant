require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Builder do
  let(:data) { { :data => [] } }

  # This returns a proc that can be used with the builder
  # that simply appends data to an array in the env.
  def appender_proc(data)
    result = Proc.new { |env| env[:data] << data }

    # Define a to_s on it for helpful output
    result.define_singleton_method(:to_s) do
      "<Appender: #{data}>"
    end

    result
  end

  context "copying" do
    it "should copy the stack" do
      copy = subject.dup
      copy.stack.object_id.should_not == subject.stack.object_id
    end
  end

  context "build" do
    it "should provide build as a shortcut for basic sequences" do
      data = {}
      proc = Proc.new { |env| env[:data] = true }

      subject = described_class.build(proc)
      subject.call(data)

      data[:data].should == true
    end
  end

  context "basic `use`" do
    it "should add items to the stack and make them callable" do
      data = {}
      proc = Proc.new { |env| env[:data] = true }

      subject.use proc
      subject.call(data)

      data[:data].should == true
    end

    it "should be able to add multiple items" do
      data = {}
      proc1 = Proc.new { |env| env[:one] = true }
      proc2 = Proc.new { |env| env[:two] = true }

      subject.use proc1
      subject.use proc2
      subject.call(data)

      data[:one].should == true
      data[:two].should == true
    end

    it "should be able to add another builder" do
      data  = {}
      proc1 = Proc.new { |env| env[:one] = true }

      # Build the first builder
      one   = described_class.new
      one.use proc1

      # Add it to this builder
      two   = described_class.new
      two.use one

      # Call the 2nd and verify results
      two.call(data)
      data[:one].should == true
    end
  end

  context "inserting" do
    it "can insert at an index" do
      subject.use appender_proc(1)
      subject.insert(0, appender_proc(2))
      subject.call(data)

      data[:data].should == [2, 1]
    end

    it "can insert by name" do
      # Create the proc then make sure it has a name
      bar_proc = appender_proc(2)
      def bar_proc.name; :bar; end

      subject.use appender_proc(1)
      subject.use bar_proc
      subject.insert_before :bar, appender_proc(3)
      subject.call(data)

      data[:data].should == [1, 3, 2]
    end

    it "can insert next to a previous object" do
      proc2 = appender_proc(2)
      subject.use appender_proc(1)
      subject.use proc2
      subject.insert(proc2, appender_proc(3))
      subject.call(data)

      data[:data].should == [1, 3, 2]
    end

    it "can insert before" do
      subject.use appender_proc(1)
      subject.insert_before 0, appender_proc(2)
      subject.call(data)

      data[:data].should == [2, 1]
    end

    it "can insert after" do
      subject.use appender_proc(1)
      subject.use appender_proc(3)
      subject.insert_after 0, appender_proc(2)
      subject.call(data)

      data[:data].should == [1, 2, 3]
    end

    it "merges middleware stacks of other builders" do
      wrapper_class = Proc.new do |letter|
        Class.new do
          def initialize(app, env)
            @app = app
          end

          define_method(:call) do |env|
            env[:data] << "#{letter}1"
            @app.call(env)
            env[:data] << "#{letter}2"
          end
        end
      end

      proc2 = appender_proc(2)
      subject.use appender_proc(1)
      subject.use proc2

      builder = described_class.new
      builder.use wrapper_class.call("A")
      builder.use wrapper_class.call("B")

      subject.insert(proc2, builder)
      subject.call(data)

      data[:data].should == [1, "A1", "B1", 2, "B2", "A2"]
    end

    it "raises an exception if an invalid object given for insert" do
      expect { subject.insert "object", appender_proc(1) }.
        to raise_error(RuntimeError)
    end

    it "raises an exception if an invalid object given for insert_after" do
      expect { subject.insert_after "object", appender_proc(1) }.
        to raise_error(RuntimeError)
    end
  end

  context "replace" do
    it "can replace an object" do
      proc1 = appender_proc(1)
      proc2 = appender_proc(2)

      subject.use proc1
      subject.replace proc1, proc2
      subject.call(data)

      data[:data].should == [2]
    end

    it "can replace by index" do
      proc1 = appender_proc(1)
      proc2 = appender_proc(2)

      subject.use proc1
      subject.replace 0, proc2
      subject.call(data)

      data[:data].should == [2]
    end
  end

  context "deleting" do
    it "can delete by object" do
      proc1 = appender_proc(1)

      subject.use proc1
      subject.use appender_proc(2)
      subject.delete proc1
      subject.call(data)

      data[:data].should == [2]
    end

    it "can delete by index" do
      proc1 = appender_proc(1)

      subject.use proc1
      subject.use appender_proc(2)
      subject.delete 0
      subject.call(data)

      data[:data].should == [2]
    end
  end

  describe "action hooks" do
    it "applies them properly" do
      hook = double("hook")
      hook.stub(:apply) do |builder|
        builder.use appender_proc(2)
      end

      data[:action_hooks] = [hook]

      subject.use appender_proc(1)
      subject.call(data)

      data[:data].should == [1, 2]
      data[:action_hooks_already_ran].should == true
    end

    it "applies without prepend/append if it has already" do
      hook = double("hook")
      hook.should_receive(:apply).with(anything, { :no_prepend_or_append => true }).once

      data[:action_hooks] = [hook]
      data[:action_hooks_already_ran] = true
      subject.call(data)
    end
  end
end
