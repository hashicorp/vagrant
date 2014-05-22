require File.expand_path("../../../base", __FILE__)

require "vagrant/util/retryable"

describe Vagrant::Util::Retryable do
  let(:klass) do
    Class.new do
      extend Vagrant::Util::Retryable
    end
  end

  it "doesn't retry by default" do
    tries = 0

    block = lambda do
      tries += 1
      raise RuntimeError, "Try"
    end

    # It should re-raise the error
    expect { klass.retryable(&block) }.
      to raise_error(RuntimeError)

    # It should've tried once
    expect(tries).to eq(1)
  end

  it "retries the set number of times" do
    tries = 0

    block = lambda do
      tries += 1
      raise RuntimeError, "Try"
    end

    # It should re-raise the error
    expect { klass.retryable(tries: 5, &block) }.
      to raise_error(RuntimeError)

    # It should've tried all specified times
    expect(tries).to eq(5)
  end

  it "only retries on the given exception" do
    tries = 0

    block = lambda do
      tries += 1
      raise StandardError, "Try"
    end

    # It should re-raise the error
    expect { klass.retryable(tries: 5, on: RuntimeError, &block) }.
      to raise_error(StandardError)

    # It should've never tried since it was a different kind of error
    expect(tries).to eq(1)
  end

  it "can retry on multiple types of errors" do
    tries = 0

    foo_error = Class.new(StandardError)
    bar_error = Class.new(StandardError)

    block = lambda do
      tries += 1
      raise foo_error, "Try" if tries == 1
      raise bar_error, "Try" if tries == 2
      raise RuntimeError, "YAY"
    end

    # It should re-raise the error
    expect { klass.retryable(tries: 5, on: [foo_error, bar_error], &block) }.
      to raise_error(RuntimeError)

    # It should've never tried since it was a different kind of error
    expect(tries).to eq(3)
  end

  it "doesn't sleep between tries by default" do
    block = lambda do
      raise RuntimeError, "Try"
    end

    # Sleep should never be called
    expect(klass).not_to receive(:sleep)

    # Run it.
    expect { klass.retryable(tries: 5, &block) }.
      to raise_error(RuntimeError)
  end

  it "sleeps specified amount between retries" do
    block = lambda do
      raise RuntimeError, "Try"
    end

    # Sleep should be called between each retry
    expect(klass).to receive(:sleep).with(10).exactly(4).times

    # Run it.
    expect { klass.retryable(tries: 5, sleep: 10, &block) }.
      to raise_error(RuntimeError)
  end
end
