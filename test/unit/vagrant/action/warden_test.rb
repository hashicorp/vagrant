require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Warden do
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

  class ExitAction
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)
    end

    def recover(env)
      env[:recover] = true
    end
  end

  let(:data) { { data: [] } }
  let(:instance) { described_class.new }

  # This returns a proc that can be used with the builder
  # that simply appends data to an array in the env.
  def appender_proc(data)
    Proc.new { |env| env[:data] << data }
  end

  it "calls the actions like normal" do
    instance = described_class.new([appender_proc(1), appender_proc(2)], data)
    instance.call(data)

    expect(data[:data]).to eq([1, 2])
  end

  it "starts a recovery sequence when an exception is raised" do
    error_proc = Proc.new { raise "ERROR!" }

    data     = { recover: [] }
    instance = described_class.new([ActionOne, ActionTwo, error_proc], data)

    # The error should be raised back up
    expect { instance.call(data) }.
      to raise_error(RuntimeError)

    # Verify the recovery process goes in reverse order
    expect(data[:recover]).to eq([2, 1])

    # Verify that the error is available in the data
    expect(data["vagrant.error"]).to be_kind_of(RuntimeError)
  end

  it "does not do a recovery sequence if SystemExit is raised" do
    # Make a proc that just calls "abort" which raises a
    # SystemExit exception.
    error_proc = Proc.new { abort }

    instance = described_class.new([ExitAction, error_proc], data)

    # The SystemExit should come through
    expect { instance.call(data) }.to raise_error(SystemExit)

    # The recover should not have been called
    expect(data.key?(:recover)).not_to be
  end

  it "does not do a recovery sequence if NoMemoryError is raised" do
    error_proc = Proc.new { raise NoMemoryError }

    instance = described_class.new([ExitAction, error_proc], data)

    # The SystemExit should come through
    expect { instance.call(data) }.to raise_error(NoMemoryError)

    # The recover should not have been called
    expect(data.key?(:recover)).not_to be
  end

  describe "dynamic action hooks" do
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
      instance = described_class.new([ActionTwo], data)
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
        instance = described_class.new([described_class.new([ActionTwo], data), ActionOne], data)
        instance.call(data)
        expect(data[:data][0]).to eq(2)
        expect(data[:data][1]).to eq(:first)
        expect(data[:data][2]).to eq(1)
      end
    end

    context "when hook uses class name" do
      let(:hook_action_name) { "ActionTwo" }

      it "should execute the hook" do
        instance = described_class.new([ActionTwo], data)
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

      let(:instance) { described_class.new([Vagrant::Test::ActionTest], data) }

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
