require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Lock do
  let(:app) { lambda { |env| } }
  let(:env) { {} }
  let(:lock_path) do
    Dir::Tmpname.create("vagrant-test-lock") {}
  end

  let(:options) do
    {
      exception: Class.new(StandardError),
      path:      lock_path
    }
  end

  after do
    File.unlink(lock_path) if File.file?(lock_path)
  end

  it "should require a path" do
    expect { described_class.new(app, env) }.
      to raise_error(ArgumentError)

    expect { described_class.new(app, env, path: "foo") }.
      to raise_error(ArgumentError)

    expect { described_class.new(app, env, exception: "foo") }.
      to raise_error(ArgumentError)

    expect { described_class.new(app, env, path: "bar", exception: "foo") }.
      to_not raise_error
  end

  it "should allow the path to be a proc" do
    inner_acquire = true
    app = lambda do |env|
      File.open(lock_path, "w+") do |f|
        inner_acquire = f.flock(File::LOCK_EX | File::LOCK_NB)
      end
    end

    options[:path] = lambda { |env| lock_path }

    instance = described_class.new(app, env, options)
    instance.call(env)

    expect(inner_acquire).to eq(false)
  end

  it "should allow the exception to be a proc" do
    exception = options[:exception]
    options[:exception] = lambda { |env| exception }

    File.open(lock_path, "w+") do |f|
      # Acquire lock
      expect(f.flock(File::LOCK_EX | File::LOCK_NB)).to eq(0)

      # Test!
      instance = described_class.new(app, env, options)
      expect { instance.call(env) }.
        to raise_error(exception)
    end
  end

  it "should call the middleware with the lock held" do
    inner_acquire = true
    app = lambda do |env|
      File.open(lock_path, "w+") do |f|
        inner_acquire = f.flock(File::LOCK_EX | File::LOCK_NB)
      end
    end

    instance = described_class.new(app, env, options)
    instance.call(env)

    expect(inner_acquire).to eq(false)
  end

  it "should raise an exception if the lock is already held" do
    File.open(lock_path, "w+") do |f|
      # Acquire lock
      expect(f.flock(File::LOCK_EX | File::LOCK_NB)).to eq(0)

      # Test!
      instance = described_class.new(app, env, options)
      expect { instance.call(env) }.
        to raise_error(options[:exception])
    end
  end

  it "should allow nesting locks within the same middleware sequence" do
    called = false
    app = lambda { |env| called = true }
    inner = described_class.new(app, env, options)
    outer = described_class.new(inner, env, options)
    outer.call(env)

    expect(called).to eq(true)
  end
end
