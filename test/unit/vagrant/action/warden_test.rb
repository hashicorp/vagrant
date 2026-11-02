# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
end
