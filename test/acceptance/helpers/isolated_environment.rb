require "fileutils"
require "pathname"

require "log4r"
require "posix-spawn"

require File.expand_path("../tempdir", __FILE__)

module Acceptance
  # This class manages an isolated environment for Vagrant to
  # run in. It creates a temporary directory to act as the
  # working directory as well as sets a custom home directory.
  class IsolatedEnvironment
    include POSIX::Spawn

    attr_reader :homedir
    attr_reader :workdir

    # Initializes an isolated environment. You can pass in some
    # options here to configure runing custom applications in place
    # of others as well as specifying environmental variables.
    #
    # @param [Hash] apps A mapping of application name (such as "vagrant")
    #   to an alternate full path to the binary to run.
    # @param [Hash] env Additional environmental variables to inject
    #   into the execution environments.
    def initialize(apps=nil, env=nil)
      @logger = Log4r::Logger.new("acceptance::isolated_environment")

      @apps = apps || {}
      @env  = env || {}

      # Create a temporary directory for our work
      @tempdir = Tempdir.new("vagrant")
      @logger.info("Initialize isolated environment: #{@tempdir.path}")

      # Setup the home and working directories
      @homedir = Pathname.new(File.join(@tempdir.path, "home"))
      @workdir = Pathname.new(File.join(@tempdir.path, "work"))

      @homedir.mkdir
      @workdir.mkdir

      @env["HOME"] = @homedir.to_s
    end

    # Executes a command in the context of this isolated environment.
    # Any command executed will therefore see our temporary directory
    # as the home directory.
    def execute(command, *argN)
      command = replace_command(command)

      # Execute in a separate process, wait for it to complete, and
      # return the IO streams.
      @logger.info("Executing: #{command} #{argN.inspect}")
      pid, stdin, stdout, stderr = popen4(@env, command, *argN, :chdir => @workdir.to_s)
      _pid, status = Process.waitpid2(pid)
      @logger.info("Exit status: #{status.exitstatus}")

      return ExecuteProcess.new(status.exitstatus, stdout, stderr)
    end

    # Closes the environment, cleans up the temporary directories, etc.
    def close
      # Delete the temporary directory
      FileUtils.rm_rf(@tempdir.path)
    end

    # This replaces a command with a replacement defined when this
    # isolated environment was initialized. If nothing was defined,
    # then the command itself is returned.
    def replace_command(command)
      return @apps[command] if @apps.has_key?(command)
      return command
    end
  end

  # This class represents a process which has run via the IsolatedEnvironment.
  # This is a readonly structure that can be used to inspect the exit status,
  # stdout, stderr, etc. from the process which ran.
  class ExecuteProcess
    attr_reader :exit_status
    attr_reader :stdout
    attr_reader :stderr

    def initialize(exit_status, stdout, stderr)
      @exit_status = exit_status
      @stdout      = stdout
      @stderr      = stderr
    end

    def success?
      @exit_status == 0
    end
  end
end

