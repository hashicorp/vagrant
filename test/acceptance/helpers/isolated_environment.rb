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

      # Set the home directory and virtualbox home directory environmental
      # variables so that Vagrant and VirtualBox see the proper paths here.
      @env["HOME"] = @homedir.to_s
      @env["VBOX_USER_HOME"] = @homedir.to_s
    end

    # Executes a command in the context of this isolated environment.
    # Any command executed will therefore see our temporary directory
    # as the home directory.
    def execute(command, *argN)
      command = replace_command(command)

      # Add our hash options to the arguments list
      argN << { :chdir => @workdir.to_s }

      # Execute in a separate process, wait for it to complete, and
      # return the IO streams.
      @logger.info("Executing: #{command} #{argN.inspect}. Output will stream in...")
      pid, stdin, stdout, stderr = popen4(@env, command, *argN)
      status = nil

      io_data = {
        stdout => "",
        stderr => ""
      }

      while results = IO.select([stdout, stderr], [stdin], nil, 5)
        # Check the readers first to see if they're ready
        readers = results[0]
        if !readers.empty?
          begin
            readers.each do |r|
              data = r.readline
              io_data[r] += data

              io_name = r == stdout ? "stdout" : "stderr"
              @logger.debug("[#{io_name}] #{data.chomp}")
              yield io_name.to_sym, data if block_given?
            end
          rescue EOFError
            # Process exited, so break out of this while loop
            break
          end
        end

        # Check here if the process has exited, and if so, exit the
        # loop.
        exit_pid, status = Process.waitpid2(pid, Process::WNOHANG)
        break if exit_pid

        # Check the writers to see if they're ready, and notify any
        # listeners...
        if !results[1].empty?
          yield :stdin, stdin if block_given?
        end
      end

      # Only load the exit status if we don't already have it, since
      # it is possible that it could've been obtained in the above
      # while loop.
      _pid, status = Process.waitpid2(pid) if !status
      @logger.debug("Exit status: #{status.exitstatus}")

      return ExecuteProcess.new(status.exitstatus, io_data[stdout], io_data[stderr])
    end

    # Closes the environment, cleans up the temporary directories, etc.
    def close
      # Delete all virtual machines
      @logger.debug("Finding all virtual machines")
      execute("VBoxManage", "list", "vms").stdout.lines.each do |line|
        data = /^"(?<name>.+?)" {(?<uuid>.+?)}$/.match(line)

        @logger.debug("Removing VM: #{data[:name]}")
        result = execute("VBoxManage", "controlvm", data[:uuid], "poweroff")
        raise Exception, "VM halt failed!" if result.exit_status != 0

        sleep 0.5

        result = execute("VBoxManage", "unregistervm", data[:uuid], "--delete")
        raise Exception, "VM unregistration failed!" if result.exit_status != 0
      end

      @logger.info("Removed all virtual machines")

      # Delete the temporary directory
      @logger.info("Removing isolated environment: #{@tempdir.path}")
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

