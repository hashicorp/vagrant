require "tempfile"
require "tmpdir"

require "vagrant/util/platform"

require "unit/support/isolated_environment"

shared_context "unit" do
  before(:each) do
    # State to store the list of registered plugins that we have to
    # unregister later.
    @_plugins = []

    # Create a thing to store our temporary files so that they aren't
    # unlinked right away.
    @_temp_files = []

    # Roughly simulate the embedded Bundler availability
    $vagrant_bundler_runtime = Object.new
  end

  after(:each) do
    # Unregister each of the plugins we have may have temporarily
    # registered for the duration of this test.
    @_plugins.each do |plugin|
      Vagrant.plugin("1").manager.unregister(plugin)
      Vagrant.plugin("2").manager.unregister(plugin)
    end
  end

  # This creates an isolated environment so that Vagrant doesn't
  # muck around with your real system during unit tests.
  #
  # The returned isolated environment has a variety of helper
  # methods on it to easily create files, Vagrantfiles, boxes,
  # etc.
  def isolated_environment
    env = Unit::IsolatedEnvironment.new
    yield env if block_given?
    env
  end

  # This registers a Vagrant plugin for the duration of a single test.
  # This will yield a new plugin class that you can then call the
  # public plugin methods on.
  #
  # @yield [plugin] Yields the plugin class for you to call the public
  #   API that you need to.
  def register_plugin(version=nil)
    version ||= Vagrant::Config::CURRENT_VERSION
    plugin = Class.new(Vagrant.plugin(version))
    plugin.name("Test Plugin #{plugin.inspect}")
    yield plugin if block_given?
    @_plugins << plugin
    plugin
  end

  # This helper creates a temporary file and returns a Pathname
  # object pointed to it.
  #
  # @return [Pathname]
  def temporary_file(contents=nil)
    dir = temporary_dir
    f = dir.join("tempfile")

    contents ||= ""
    f.open("w") do |f|
      f.write(contents)
      f.flush
    end

    return Pathname.new(Vagrant::Util::Platform.fs_real_path(f.to_s))
  end

  # This creates a temporary directory and returns a {Pathname}
  # pointing to it. If a block is given, the pathname is yielded and the
  # temporary directory is removed at the end of the block.
  #
  # @return [Pathname]
  def temporary_dir
    # Create a temporary directory and append it to the instance
    # variabe so that it isn't garbage collected and deleted
    d = Dir.mktmpdir("vagrant-temporary-dir")
    @_temp_files ||= []
    @_temp_files << d

    # Return the pathname
    result = Pathname.new(Vagrant::Util::Platform.fs_real_path(d))
    if block_given?
      begin
        yield result
      ensure
        FileUtils.rm_rf(result)
      end
    end

    return result
  end

  # Stub the given environment in ENV, without actually touching ENV. Keys and
  # values are converted to strings because that's how the real ENV works.
  def stub_env(hash)
    allow(ENV).to receive(:[]).and_call_original

    hash.each do |key, value|
      allow(ENV).to receive(:[])
        .with(key.to_s)
        .and_return(value.to_s)
    end
  end

  # This helper provides temporary environmental variable changes.
  def with_temp_env(environment)
    # Build up the new environment, preserving the old values so we
    # can replace them back in later.
    old_env = {}
    environment.each do |key, value|
      key          = key.to_s
      old_env[key] = ENV[key]
      ENV[key]     = value
    end

    # Call the block, returning its return value
    return yield
  ensure
    # Reset the environment no matter what
    old_env.each do |key, value|
      ENV[key] = value
    end
  end

  # This helper provides a randomly available port(s) for each argument to the
  # block.
  def with_random_port(&block)
    ports = []

    block.arity.times do
      server = TCPServer.new('127.0.0.1', 0)
      ports << server.addr[1]
      server.close
    end

    block.call(*ports)
  end
end
