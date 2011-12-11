require "log4r"
require "childprocess"

require "acceptance/support/virtualbox"
require "support/isolated_environment"

module Acceptance
  # This class manages an isolated environment for Vagrant to
  # run in. It creates a temporary directory to act as the
  # working directory as well as sets a custom home directory.
  class IsolatedEnvironment < ::IsolatedEnvironment
    def initialize(apps=nil, env=nil)
      super()

      @logger = Log4r::Logger.new("acceptance::isolated_environment")

      @apps = apps || {}
      @env  = env || {}

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

      # Get the hash options passed to this method
      options = argN.last.is_a?(Hash) ? argN.pop : {}
      timeout = options.delete(:timeout)

      # Build a child process to run this command. For the stdout/stderr
      # we use pipes so that we can select() on it and block and stream
      # data in as it comes.
      @logger.info("Executing: #{command} #{argN.inspect}. Output will stream in...")
      process = ChildProcess.build(command, *argN)
      stdout, stdout_writer = IO.pipe
      process.io.stdout = stdout_writer

      stderr, stderr_writer = IO.pipe
      process.io.stderr = stderr_writer
      process.duplex = true

      @env.each do |k, v|
        process.environment[k] = v
      end

      Dir.chdir(@workdir.to_s) do
        process.start
        process.io.stdin.sync = true
      end

      # Close our side of the pipes, since we're just reading
      stdout_writer.close
      stderr_writer.close

      # Create a hash to store all the data we see.
      io_data = { stdout => "", stderr => "" }

      # Record the start time for timeout purposes
      start_time = Time.now.to_i

      @logger.debug("Selecting on IO...")
      while true
        results = IO.select([stdout, stderr],
                            [process.io.stdin], nil, timeout || 5)

        # Check if we have exceeded our timeout from waiting on a select()
        raise TimeoutExceeded, process.pid if timeout && (Time.now.to_i - start_time) > timeout

        # Check the readers first to see if they're ready
        readers = results[0]
        if !readers.empty?
          begin
            readers.each do |r|
              data = r.read_nonblock(1024)
              io_data[r] += data
              io_name = r == stdout ? "stdout" : "stderr"
              @logger.debug(data)
              yield io_name.to_sym, data if block_given?
            end
          rescue IO::WaitReadable
            # This just means the IO wasn't actually ready and we should
            # wait some more. So we just let this pass through.
          rescue EOFError
            # Process exited, so break out of this while loop
            break
          end
        end

        # Check if the process exited in order to break the loop before
        # we try to see if any stdin is ready.
        break if process.exited?

        # Check the writers to see if they're ready, and notify any listeners
        if !results[1].empty?
          yield :stdin, process.io.stdin if block_given?
        end
      end

      # Continually try to wait for the process to end, but do so asynchronously
      # so that we can also check to see if we have exceeded a timeout.
      begin
        # If a timeout is not set, we set a very large timeout to
        # simulate "forever"
        @logger.debug("Waiting for process to exit...")
        remaining = (timeout || 32000) - (Time.now.to_i - start_time)
        remaining = 0 if remaining < 0
        process.poll_for_exit(remaining)
      rescue ChildProcess::TimeoutError
        raise TimeoutExceeded, process.pid
      end

      @logger.debug("Exit status: #{process.exit_code}")
      return ExecuteProcess.new(process.exit_code, io_data[stdout], io_data[stderr])
    end

    # Closes the environment, cleans up the temporary directories, etc.
    def close
      # Only delete virtual machines if VBoxSVC is running, meaning
      # that something related to VirtualBox started running in this
      # environment.
      delete_virtual_machines if VirtualBox.find_vboxsvc

      # Let the parent handle cleaning up
      super
    end

    def delete_virtual_machines
      # Delete all virtual machines
      @logger.debug("Finding all virtual machines")
      execute("VBoxManage", "list", "vms").stdout.lines.each do |line|
        data = /^"(?<name>.+?)" {(?<uuid>.+?)}$/.match(line)

        begin
          @logger.debug("Removing VM: #{data[:name]}")

          # We add a timeout onto this because sometimes for seemingly no
          # reason it will simply freeze, although the VM is successfully
          # "aborted." The timeout gets around this strange behavior.
          execute("VBoxManage", "controlvm", data[:uuid], "poweroff", :timeout => 5)
        rescue TimeoutExceeded => e
          @logger.info("Failed to poweroff VM '#{data[:uuid]}'. Killing process.")

          # Kill the process and wait a bit for it to disappear
          Process.kill('KILL', e.pid)
          Process.waitpid2(e.pid)
        end

        sleep 0.5

        result = execute("VBoxManage", "unregistervm", data[:uuid], "--delete")
        raise Exception, "VM unregistration failed!" if result.exit_status != 0
      end

      @logger.info("Removed all virtual machines")
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

  # This exception is raised if the timeout for a process is exceeded.
  class TimeoutExceeded < StandardError
    attr_reader :pid

    def initialize(pid)
      @pid = pid

      super()
    end
  end
end

