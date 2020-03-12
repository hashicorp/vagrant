require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Builder do
  let(:data) { { data: [] } }

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

  def wrapper_proc(data)
    Class.new do
      def initialize(app, env)
        @app = app
      end

      def self.name
        "TestAction"
      end

      define_method(:call) do |env|
        env[:data] << "#{data}_in"
        @app.call(env)
        env[:data] << "#{data}_out"
      end
    end
  end

  context "copying" do
    it "should copy the stack" do
      copy = subject.dup
      expect(copy.stack.object_id).not_to eq(subject.stack.object_id)
    end
  end

  context "build" do
    it "should provide build as a shortcut for basic sequences" do
      data = {}
      proc = Proc.new { |env| env[:data] = true }

      subject = described_class.build(proc)
      subject.call(data)

      expect(data[:data]).to eq(true)
    end
  end

  context "basic `use`" do
    it "should add items to the stack and make them callable" do
      data = {}
      proc = Proc.new { |env| env[:data] = true }

      subject.use proc
      subject.call(data)

      expect(data[:data]).to eq(true)
    end

    it "should be able to add multiple items" do
      data = {}
      proc1 = Proc.new { |env| env[:one] = true }
      proc2 = Proc.new { |env| env[:two] = true }

      subject.use proc1
      subject.use proc2
      subject.call(data)

      expect(data[:one]).to eq(true)
      expect(data[:two]).to eq(true)
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
      expect(data[:one]).to eq(true)
    end
  end

  context "inserting" do
    it "can insert at an index" do
      subject.use appender_proc(1)
      subject.insert(0, appender_proc(2))
      subject.call(data)

      expect(data[:data]).to eq([2, 1])
    end

    it "can insert by name" do
      # Create the proc then make sure it has a name
      bar_proc = appender_proc(2)
      def bar_proc.name; :bar; end

      subject.use appender_proc(1)
      subject.use bar_proc
      subject.insert_before :bar, appender_proc(3)
      subject.call(data)

      expect(data[:data]).to eq([1, 3, 2])
    end

    it "can insert next to a previous object" do
      proc2 = appender_proc(2)
      subject.use appender_proc(1)
      subject.use proc2
      subject.insert(proc2, appender_proc(3))
      subject.call(data)

      expect(data[:data]).to eq([1, 3, 2])
    end

    it "can insert before" do
      subject.use appender_proc(1)
      subject.insert_before 0, appender_proc(2)
      subject.call(data)

      expect(data[:data]).to eq([2, 1])
    end

    it "can insert after" do
      subject.use appender_proc(1)
      subject.use appender_proc(3)
      subject.insert_after 0, appender_proc(2)
      subject.call(data)

      expect(data[:data]).to eq([1, 2, 3])
    end

    it "merges middleware stacks of other builders" do
      wrapper_class = Proc.new do |letter|
        Class.new do
          def initialize(app, env)
            @app = app
          end

          def self.name
            "TestAction"
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

      expect(data[:data]).to eq([1, "A1", "B1", 2, "B2", "A2"])
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

      expect(data[:data]).to eq([2])
    end

    it "can replace by index" do
      proc1 = appender_proc(1)
      proc2 = appender_proc(2)

      subject.use proc1
      subject.replace 0, proc2
      subject.call(data)

      expect(data[:data]).to eq([2])
    end
  end

  context "deleting" do
    it "can delete by object" do
      proc1 = appender_proc(1)

      subject.use proc1
      subject.use appender_proc(2)
      subject.delete proc1
      subject.call(data)

      expect(data[:data]).to eq([2])
    end

    it "can delete by index" do
      proc1 = appender_proc(1)

      subject.use proc1
      subject.use appender_proc(2)
      subject.delete 0
      subject.call(data)

      expect(data[:data]).to eq([2])
    end
  end

  describe "action hooks" do
    let(:hook) { double("hook") }
    let(:manager) { Vagrant.plugin("2").manager }

    before do
      allow(manager).to receive(:action_hooks).and_return([])
    end

    it "applies them properly" do
      hook_proc = proc{ |h| h.append(appender_proc(2)) }
      expect(manager).to receive(:action_hooks).with(:test_action).
        and_return([hook_proc])

      data[:action_name] = :test_action

      subject.use appender_proc(1)
      subject.call(data)

      expect(data[:data]).to eq([1, 2])
      expect(data[:action_hooks_already_ran]).to eq(true)
    end

    it "applies without prepend/append if it has already" do
      hook_proc = proc{ |h| h.append(appender_proc(2)) }
      expect(manager).to receive(:action_hooks).with(:test_action).
        and_return([hook_proc])

      data[:action_name] = :test_action

      subject.use appender_proc(1)
      subject.call(data.merge(action_hooks_already_ran: true))

      expect(data[:data]).to eq([1])
      subject.call(data)
    end
  end

  describe "calling another app later" do
    it "calls in the proper order" do
      # We have to do this because inside the Class.new, it can't see these
      # rspec methods...
      described_klass = described_class
      wrapper_proc    = self.method(:wrapper_proc)

      wrapper = Class.new do
        def initialize(app, env)
          @app = app
        end

        def self.name
          "TestAction"
        end

        define_method(:call) do |env|
          inner = described_klass.new
          inner.use wrapper_proc[2]
          inner.use @app
          inner.call(env)
        end
      end

      subject.use wrapper_proc(1)
      subject.use wrapper
      subject.use wrapper_proc(3)
      subject.call(data)

      expect(data[:data]).to eq([
        "1_in", "2_in", "3_in", "3_out", "2_out", "1_out"])
    end
  end

  describe "dynamic action hooks" do
    class ActionOne
      def initialize(app, env)
        @app = app
      end

      def call(env)
        env[:data] << 1 if env[:data]
        @app.call(env)
      end

      def recover(env)
        env[:recover] << 1
      end
    end

    class ActionTwo
      def initialize(app, env)
        @app = app
      end

      def call(env)
        env[:data] << 2 if env[:data]
        @app.call(env)
      end

      def recover(env)
        env[:recover] << 2
      end
    end

    let(:data) { {data: []} }
    let(:hook_action_name) { :action_two }

    let(:plugin) do
      h_name = hook_action_name
      @plugin ||= Class.new(Vagrant.plugin("2")) do
        name "Test Plugin"
        action_hook(:before_test, h_name) do |hook|
          hook.prepend(proc{ |env| env[:data] << :first })
        end
      end
    end

    before { plugin }

    after do
      Vagrant.plugin("2").manager.unregister(@plugin) if @plugin
      @plugin = nil
    end

    it "should call hook before running action" do
      instance = described_class.build(ActionTwo)
      instance.call(data)
      expect(data[:data].first).to eq(:first)
      expect(data[:data].last).to eq(2)
    end

    context "when hook is appending to action" do
      let(:plugin) do
        @plugin ||= Class.new(Vagrant.plugin("2")) do
          name "Test Plugin"
          action_hook(:before_test, :action_two) do |hook|
            hook.append(proc{ |env| env[:data] << :first })
          end
        end
      end

      it "should call hook after action when action is nested" do
        instance = described_class.build(ActionTwo).use(described_class.build(ActionOne))
        instance.call(data)
        expect(data[:data][0]).to eq(2)
        expect(data[:data][1]).to eq(:first)
        expect(data[:data][2]).to eq(1)
      end
    end

    context "when hook uses class name" do
      let(:hook_action_name) { "ActionTwo" }

      it "should execute the hook" do
        instance = described_class.build(ActionTwo)
        instance.call(data)
        expect(data[:data]).to include(:first)
      end
    end

    context "when action includes a namespace" do
      module Vagrant
        module Test
          class ActionTest
            def initialize(app, env)
              @app = app
            end

            def call(env)
              env[:data] << :test if env[:data]
              @app.call(env)
            end
          end
        end
      end

      let(:instance) { described_class.build(Vagrant::Test::ActionTest) }

      context "when hook uses short snake case name" do
        let(:hook_action_name) { :action_test }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end

      context "when hook uses partial snake case name" do
        let(:hook_action_name) { :test_action_test }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end

      context "when hook uses full snake case name" do
        let(:hook_action_name) { :vagrant_test_action_test }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end

      context "when hook uses short class name" do
        let(:hook_action_name) { "ActionTest" }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end

      context "when hook uses partial namespace class name" do
        let(:hook_action_name) { "Test::ActionTest" }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end

      context "when hook uses full namespace class name" do
        let(:hook_action_name) { "Vagrant::Test::ActionTest" }

        it "should execute the hook" do
          instance.call(data)
          expect(data[:data]).to include(:first)
        end
      end
    end
  end
end
