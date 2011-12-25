require "acceptance/support/isolated_environment"
require "acceptance/support/output"
require "acceptance/support/virtualbox"

shared_context "acceptance" do
  # Setup variables for the loggers of this test. These can be used to
  # create more verbose logs for tests which can be useful in the case
  # that a test fails.
  let(:logger_name) { "logger" }
  let(:logger) { Log4r::Logger.new("test::acceptance::#{logger_name}") }

  # This is the global configuration given by the acceptance test
  # configurations.
  let(:config) { $acceptance_options }

  # Setup the environment so that we have an isolated area
  # to run Vagrant. We do some configuration here as well in order
  # to replace "vagrant" with the proper path to Vagrant as well
  # as tell the isolated environment about custom environmental
  # variables to pass in.
  let!(:environment) { new_environment }

  before(:each) do
    # Wait for VBoxSVC to disappear, since each test requires its
    # own isolated VirtualBox process.
    Acceptance::VirtualBox.wait_for_vboxsvc
  end

  after(:each) do
    environment.close
  end

  # Creates a new isolated environment instance each time it is called.
  #
  # @return [Acceptance::IsolatedEnvironment]
  def new_environment(env=nil)
    apps = { "vagrant" => config.vagrant_path }
    env  = config.env.merge(env || {})

    Acceptance::IsolatedEnvironment.new(apps, env)
  end

  # Executes the given command in the context of the isolated environment.
  #
  # @return [Object]
  def execute(*args, &block)
    environment.execute(*args, &block)
  end

  # This method is an assertion helper for asserting that a process
  # succeeds. It is a wrapper around `execute` that asserts that the
  # exit status was successful.
  def assert_execute(*args, &block)
    result = execute(*args, &block)
    assert(result.exit_code == 0, "expected '#{args.join(" ")}' to succeed")
    result
  end

  # This can be added to the beginning of a test to verify that the
  # box with the given name is available to a test. This will raise
  # an exception if the box is not found.
  def require_box(name)
    if !File.exist?(box_path(name))
      raise ArgumentError, "The tests should have a '#{name}' box."
    end
  end

  # This is used to get the path to a box of a specific name.
  def box_path(name)
    File.join(config.box_directory, "#{name}.box")
  end
end
