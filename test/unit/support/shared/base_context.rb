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

    return Pathname.new(f)
  end
end
