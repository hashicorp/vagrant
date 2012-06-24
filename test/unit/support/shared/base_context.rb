require "tempfile"

require "unit/support/isolated_environment"

shared_context "unit" do
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

  # This helper creates a temporary file and returns a Pathname
  # object pointed to it.
  def temporary_file(contents=nil)
    f = Tempfile.new("vagrant-unit")

    if contents
      f.write(contents)
      f.flush
    end

    return Pathname.new(f.path)
  end

  # This helper provides temporary environmental variable changes.
  def with_temp_env(environment)
    # Build up the new environment, preserving the old values so we
    # can replace them back in later.
    old_env = {}
    environment.each do |key, value|
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
end
