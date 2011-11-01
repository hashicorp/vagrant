require 'net/ssh'
require 'net/scp'
require 'aruba/api'
$stdout.sync=true if not $stdout.sync
$stderr.sync=true if not $stderr.sync

module Vagrant
  # Manages SSH access to a specific environment. Allows an environment to
  # replace the process with SSH itself, run a specific set of commands,
  # upload files, or even check if a host is up.
  class SSH
    # Inorder to utilize Aruba assertions about exit status and success.
    require 'rspec/expectations'
    include RSpec::Matchers

    include Util::Retryable
    include Util::SafeExec
    include ::Aruba::Api

    # Reference back up to the environment which this SSH object belongs to
    attr_accessor :env
    attr_reader :session

    def initialize(environment)
      @env = environment
      @current_session = nil
    end

    def build_options(opts={})
      options = opts.dup
      # We have to determine the port outside of the block since it uses
      # API calls which can only be used from the main thread in JRuby on
      # Windows
      options[:port] = port(opts)
      [:host, :username, :private_key_path, :shared_connections].each do |param|
        options[param] = opts[param] || env.config.ssh.send(param)
      end
      options
    end

    # Connects to the environment's virtual machine, replacing the ruby
    # process with an SSH process. This method optionally takes a hash
    # of options which override the configuration values.
    # This method is invoked by the cli `vagrant ssh <vm_name>` hence should not
    # be deprecated or replaced by the Aruba/ChildProcess script-able connections.
    def connect(opts={})
      if Util::Platform.windows?
        raise Errors::SSHUnavailableWindows, :key_path => env.config.ssh.private_key_path,
                                             :ssh_port => port(opts)
      end

      raise Errors::SSHUnavailable if !Kernel.system("which ssh > /dev/null 2>&1")

      options = build_options(opts)

      check_key_permissions(options[:private_key_path])

      command = ssh_command(options)
      # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
      # (GH-51). As a workaround, we fork and wait. On all other platforms,
      # we simply exec.
      env.logger.info("ssh") { "Invoking SSH: #{command}" }
      safe_exec(command)
    end

    def ssh_peculiar_options(options)
      options[:port] = port unless options[:port]
      ["-p #{options[:port]}"].join(" ")
    end


    def scp_peculiar_options(options)
      ["-P #{options[:port]}"].join(" ")
    end


    def ssh_command_options(options)
      ssh_options = []
      if env.config.ssh.shared_connections
        ssh_options << "-o ControlPath=#{env.config.ssh.get_control_path}"
        ssh_options << "-o ControlMaster=auto"
      else
        ssh_options << "-o ControlMaster=no"
      end

      ["-o UserKnownHostsFile=/dev/null",
       "-o StrictHostKeyChecking=no", "-o IdentitiesOnly=yes",
       "-i #{options[:private_key_path]}"].each{|opt| ssh_options << opt}

      ssh_options << "-o ForwardAgent=yes" if env.config.ssh.forward_agent

      if env.config.ssh.forward_x11
        # Both are required so that no warnings are shown regarding X11
        ssh_options << "-o ForwardX11=yes"
        ssh_options << "-o ForwardX11Trusted=yes"
      end

      ssh_options << "-o ConnectTimeout=#{env.config.ssh.connect_timeout}"
      if env.config.ssh.keep_alive_interval
        ssh_options << "-o KeepAlive=yes"
        ssh_options << "-o ServerAliveInterval=#{env.config.ssh.keep_alive_interval}"
      end

      ssh_options.join(" ")
    end

    def control_master_command(vagrant_options=build_options)
      @control_master_command ||= "ssh -t -t -n -N #{ssh_peculiar_options(vagrant_options)} #{ssh_command_options(vagrant_options)} #{vagrant_options[:username]}@#{vagrant_options[:host]}"
    end

    #Return the pid of the session process
    def pid
      temp_pid = session.instance_variable_get(("@process").intern).pid
      temp_pid.nil? ? nil : temp_pid.to_i
    end

    # Return true if the SSH control master connection is alive.
    def control_master_alive?
      proc = get_process(@control_master_command) if @control_master_command
      childproc = proc.instance_variable_get(:@process)
      if childproc
        childproc.alive?
      else
        false
      end
    end

    # start the SSH control master connection and place it in the background.
    def start_control_master(options=build_options)
      cmd = control_master_command(build_options)
      check_key_permissions(env.config.ssh.private_key_path)
      env.ui.info("Starting the SSH control master connection: #{cmd[0..20]} <snip>...")
      aruba_timeout
      run_interactive( cmd )
      env.ui.info("Started the SSH control master connection (pid: #{pid}) control path: #{env.config.ssh.get_control_path}.")
      env.config.ssh.master_connection = session
    end


    def ssh_command(vagrant_options)
      cmd = "ssh -t -t #{ssh_peculiar_options(vagrant_options)} #{ssh_command_options(vagrant_options)} #{vagrant_options[:username]}@#{vagrant_options[:host]}"
      cmd += " '#{unescape(vagrant_options[:command])}'" if vagrant_options[:command]
      unescape(cmd.strip)
    end


    def scp_command(vagrant_options, from, to)
      # Do not pass `-t -t` option to scp.
      unescape("scp #{scp_peculiar_options(vagrant_options)} #{ssh_command_options(vagrant_options)} #{from} #{vagrant_options[:username]}@#{vagrant_options[:host]}:#{to}".strip)
    end

    # In order to run Aruba's subprocess helper methods:
    # Interactive connection to the environment's virtual machine, replacing the ruby
    # process with an SSH process. This method optionally takes a hash
    # of options which override the configuration values.
    # TODO rename this method to script_connect or script_block_connect
    def interactive_connect(opts={})
      if Util::Platform.windows?
        raise Errors::SSHUnavailableWindows, :key_path => env.config.ssh.private_key_path,
                                             :ssh_port => port(opts)
      end

      raise Errors::SSHUnavailable if !Kernel.system("which ssh > /dev/null 2>&1")

      options = {}
      options[:port] = port(opts)
      [:host, :username, :private_key_path].each do |param|
        options[param] = opts[param] || env.config.ssh.send(param)
      end

      check_key_permissions(options[:private_key_path])

      command = ssh_command(options)
      env.logger.info("ssh") { "Invoking SSH: #{command}" }

      #env.config.ssh.master_connection = command
      aruba_timeout
      begin
        env.ui.info("Starting SSH input session: #{command[0..20]} <snip>...")
        run_interactive(command)
        # wait for the remote shell to accept commands. This is critical.
        # This exception should never be raised
        raise(IOError, 'The remote session is not ready') unless wait_for_ssh_shell
        env.ui.info("Started SSH input session (pid: #{pid}) control path: #{env.config.ssh.get_control_path}.")
      rescue => e
        env.logger.info("ssh") { "#{e.message}: #{caller.join('\n')}" }
      end
    end

    # This is one-more-thing to stomp bugs behind:
    # Vagrant issues #391, #455
    # Veewee issues:
    # It is common to have three attempts, so 20 trials (2 seconds) seems patient enough.
    def wait_for_ssh_shell
      env.ui.info "Waiting for the remote shell to accept commands..."
      count = 1
      begin
          while true
            command = "/bin/bash -c 'exit 111'"
            execute { |ssh| ssh.vagrant_type(ssh.vagrant_remote_cmd(command)) }
            #This will raise an error which we catch below
            result = parse_last_remote_status( get_name(session), command, {} )
            break if count > 20  # Don't try forever'
            sleep 0.1
            count += 1
            env.logger.info "The remote shell is NOT ready (after #{count} attempts)."
          end
          env.ui.info "The remote shell is ready for commands (after #{count} attempts)." if count == 1
          env.ui.info "The remote shell is NOT ready (after #{count} attempts)." if count > 20
        return false
      rescue Vagrant::Errors::VagrantError => e
        if e.message[/\/bin\/bash -c 'exit 111'/]
          env.ui.info "The remote shell is ready for input (after #{count} attempts)."
          parse_ssh_connection
          return true
        else
          raise
        end
      rescue Errno::EPIPE => e
        env.ui.info "The remote shell is NOT ready (after #{count} attempts). Report a bug if the VM is NOT halting."
        env.ui.info "#{e.inspect} #{caller.join('\n')}"
        return false
      rescue => e
        env.ui.info "The remote shell is NOT ready (after #{count} attempts).  Error: #{e.inspect}."
        return false
      end

    end


    def create_connection(opts)
      # Check the key permissions to avoid SSH hangs
      check_key_permissions(env.config.ssh.private_key_path)
      # Merge in any additional options
      opts = opts.dup
      opts[:forward_agent] = true if env.config.ssh.forward_agent
      opts[:port] ||= port

      # The exceptions which are acceptable to retry on during
      # attempts to connect to SSH
      exceptions = [Errno::ECONNREFUSED, Net::SSH::Disconnect]

      # Connect to SSH and gather the session
      retryable(:tries => 5, :on => exceptions) do
        interactive_connect(opts)
      end
      vagrant_type( vagrant_remote_cmd( "export TERM=vt100" ) )
      distro? unless env.config.vm.distribution
      session
    end

    # Opens an SSH connection to this environment's virtual machine and yields
    # a Aruba::Process object which can be used to execute remote commands.
    def execute(opts={})
      begin
        opts = opts.dup

        start_control_master(opts) unless control_master_alive?

        # New SSH input connections will use the SSH control master connection
        create_connection(opts) unless get_connection

        distro? unless env.config.vm.distribution

        # Yield our session for executing
        return yield self if block_given?
      rescue Errno::ECONNREFUSED
        raise Errors::SSHConnectionRefused
      ensure
        # output the stdout (std error is redirected to stdout on the remote/VM.  See vagrant_remote_cmd.
        #show_connection_output
      end

    end

    # Uploads a file from `from` to `to`. `from` and `to` is expected to be a filename path.
    # This method simply invokes a scp command.
    #
    # TODO check for scp executable the same way we check for ssh executable
    #def upload!(from, to)
    #  retryable(:tries => 5, :on => [IOError]) do
    #    cmd = scp_command(build_options, from, to)
    #    env.ui.info("Uploading [#{from}] to [#{to}] (command #{cmd})...")
    #    result = run_simple(cmd, fail_on_error=false)
    #    env.ui.info("Uploaded [#{from}] to [#{to}] (result #{result.inspect}).")
    #    true
    #  end
    #end

    # Upload via scp can be as fragile as establishing a SSH input session, so we establish a session,
    #then issue the scp command, and reissue the upload scp if the file is not uploaded.
    def upload!(from, to)
      cmd = scp_command(build_options, from, to)
      count = 1
      begin
        # test negative of existence, grab the status, re-test to raise the VagrantError which is
        # trapped, inspected then true returned or re-raised.
        command = "/bin/bash -c 'test ! -f #{to};echo upload_status_$?;test ! -f #{to};'"
          while true
            execute do |ssh|
              env.ui.info("Uploading [#{from}] to [#{to}]...")
              result = run_simple(cmd, fail_on_error=false)
              ssh.vagrant_type(ssh.vagrant_remote_cmd(command))
            end
            #This will raise an error which we catch below
            result = parse_last_remote_status( get_name(session), command, {} )
            break if count > 20  # Don't try forever'
            sleep 0.1
            count += 1
            env.logger.info "Upload of [#{from}] to [#{to}] has NOT succeeded (after #{count} attempts)."
          end
          env.ui.info "Upload of [#{from}] to [#{to}] has succeeded (after #{count} attempts)." if count == 1
          env.ui.info "Upload of [#{from}] to [#{to}] has NOT succeeded (after #{count} attempts)." if count > 20
        return false
      rescue ::Vagrant::Errors::VagrantError => e
        if e.message[/upload_status_1/]
          env.ui.info "Upload of [#{from}] to [#{to}] has succeeded (after #{count} attempts)."
          return true
        else
          raise
        end
      rescue Errno::EPIPE
        env.ui.info "Upload of [#{from}] to [#{to}] has NOT succeeded. Report a bug if the VM is NOT halting."
        return false
      rescue => e
        env.ui.info "Upload of [#{from}] to [#{to}] has NOT succeeded. Error: #{e.inspect}."
        return false
      end
    end

    # Checks if this environment's machine is up (i.e. responding to SSH).
    # Usually this is first cab off the rank in connecting to the VM.  We take care with timeout to
    # ensure that SSh connections do not overlap. Please do not change ssh.connect_timeout values unless you
    # are confident you know what you are doing.
    #
    # The default retries each 3 sec, for 2.5 min. Increase the connect_timeout by 1 sec and max boot time lengthens by
    # 26 sec (51*1)
    #
    #
    # @return [Boolean]
    def up?
      # NOTE:
      # This methods' default timeoutsettings are quite conservative in establishing the initial
      # SSH connection.
      # See issues #391 and #455 for a history no  one wants to repeat.
      #
      opts = build_options( :command => 'echo $SSH_CONNECTION')
      check_key_permissions(opts[:private_key_path])

      cmd = ssh_command( opts )
        exceptions = [::Vagrant::Errors::SSHBannerExchange, ::ChildProcess::TimeoutError, IOError, ::Vagrant::Errors::SSHUnavailable ]
        retryable(:tries => 12, :on => exceptions, :sleep => env.config.ssh.connect_timeout + 1 ) do
          env.logger.info("ssh") {"Waiting on a SSH responsive connection via the command: #{cmd}"}
          # Since the VM is often not fully-booted when this method is called, we cannot use
          # the interactive_connect+execute+vagrant_type method sequence.
          begin
            run_simple(cmd, fail_on_error = true)
          rescue => e
            if e.message[/Exit status was 255 but expected it to be 0/,0]
              raise ::Vagrant::Errors::SSHBannerExchange, {:output => e.message}
            end
          end
        end
      #end
      # Setup SSH control master in the background
      start_control_master(opts)
      true
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect,
           Errors::SSHConnectionRefused, Net::SSH::AuthenticationFailed
    rescue ChildProcess::TimeoutError
      env.logger.info("ssh") { show_all_connection_output }
      return false
    end

    # Checks the file permissions for the private key, resetting them
    # if needed, or on failure erroring.
    def check_key_permissions(key_path)
      # Windows systems don't have this issue
      return if Util::Platform.windows?

      env.logger.info("ssh") { "Checking key permissions: #{key_path}" }

      stat = File.stat(key_path)

      if stat.owned? && file_perms(key_path) != "600"
        env.logger.info("ssh") { "Attempting to correct key permissions to 0600" }

        File.chmod(0600, key_path)
        raise Errors::SSHKeyBadPermissions, :key_path => key_path if file_perms(key_path) != "600"
      end
    rescue Errno::EPERM
      # This shouldn't happen since we verify we own the file, but just
      # in case.
      raise Errors::SSHKeyBadPermissions, :key_path => key_path
    end

    # Returns the file permissions of a given file. This is fairly unix specific
    # and probably doesn't belong in this class. Will be refactored out later.
    def file_perms(path)
      perms = sprintf("%o", File.stat(path).mode)
      perms.reverse[0..2].reverse
    end

    # Returns the port which is either given in the options hash or taken from
    # the config by finding it in the forwarded ports hash based on the
    # `config.ssh.forwarded_port_key`.
    def port(opts={})
      # Check if port was specified in options hash
      return opts[:port] if opts[:port]

      # Check if a port was specified in the config
      return env.config.ssh.port if env.config.ssh.port

      # Check if we have an SSH forwarded port
      pnum_by_name = nil
      pnum_by_destination = nil
      env.vm.vm.network_adapters.each do |na|
        # Look for the port number by name...
        pnum_by_name = na.nat_driver.forwarded_ports.detect do |fp|
          fp.name == env.config.ssh.forwarded_port_key
        end

        # Look for the port number by destination...
        pnum_by_destination = na.nat_driver.forwarded_ports.detect do |fp|
          fp.guestport == env.config.ssh.forwarded_port_destination
        end

        # pnum_by_name is what we're looking for here, so break early
        # if we have it.
        break if pnum_by_name
      end

      return pnum_by_name.hostport if pnum_by_name
      return pnum_by_destination.hostport if pnum_by_destination

      # This should NEVER happen.
      raise Errors::SSHPortNotDetected
    end

    # Executes a given command and simply returns true/false if the
    # command succeeded or not.
    def test?(command)
      begin
        result = exec!(command)
      rescue
      ensure
        env.logger.info("ssh") { "Command test result: #{result}" }
        result
      end
    end

    # TODO: refactor VM distribution test to use Ohai on the guest VM
    def distro?
      return env.config.vm.distribution
    end


    def aruba_timeout(seconds = (env.config.ssh.connect_timeout + 2) )
      @aruba_timeout_seconds = seconds
    end


    def vagrant_remote_cmd(cmd)
      #vagrant-ssh-remote-command-exit-status
      vg_cmd = "#{cmd}\necho \"vsrces:$?\""
    end

    # Type the command into the SSH session. Log the content and sent character count (includes new lines).
    def vagrant_type(cmd)
      env.logger.info("Typing command: #{cmd}" )
      cnt = type(cmd)
      env.logger.info("Typed character count: #{cnt}" )
    end

    # Closes all Aruba/ChildProcesses that were started by an `ssh` or `scp` command.
    # Closes SSH processes by issuing the SSH 'exit' command to each that is alive.
    # Once all non-control-master processes are exited, exit the control master process
    def exit_all
      env.ui.info("Exiting the SSH sessions...") if  processes.size > 0
      processes.reverse.each do |name, process|
        next if name == @control_master_command
        if name =~ /^ssh |^scp /
          env.logger.info("ssh") { "Exiting the SSH session and process started by the command: #{name}" }
          begin
            change_session(name)
            exit_and_log(name)
          rescue Errno::EPIPE
            # This should no longer be seen now that we use alive?.
            env.logger.info("ssh")  { "We have already closed the process started by the command: #{name}" }
          ensure
          end
        end
        parse_last_remote_status([name].flatten, 'exit', build_options)
      end
      @exit_control_master = true
      processes.reverse.each do |name, process|
        if name !=  @control_master_command
          change_session(name)
          if alive?
            env.ui.info("ALERT: A SSH session and process is still alive.  Trying to exit again...")
            exit_and_log(name)
            @exit_control_master = false if alive?
          end
        end
      end
      if @exit_control_master
        exit_control_master
      else
        # Raise an error, output the processes list contents.
        env.ui.info("ALERT: The SSH master control session has not been closed due to a residual open SSH input or copy session.  Please report this as a bug.")
      end
      env.ui.info("Exited the SSH sessions.") if  processes.size > 0
    end


    def archived_outputs(name = '', output='')
      @archived_outputs ||= ''
      if output.size > 0
        @archived_outputs << "The following is output from the SSH connection #{name}:\n"
        @archived_outputs << output
      end
      @archived_outputs
    end

    def exit_control_master
      change_session(@control_master_command)
      result = nil
      if alive?
        #This is the SSH control master session, so we can't send 'exit'' to it,
        #but we still have to exit it cleanly... so `kill_ssh( name )` is not an option.
        #Note also that by reversing the processors list we should be ending the master control process after
        #the input/copy sessions have been closed, (so the control process may have already exited?)
        #Occasionally the control mater process can be orphaned, and has to be killed directly rather than
        #shutdown via the SSH control command.
        env.ui.info("Exiting the SSH master control session (pid: #{pid}) control path: #{env.config.ssh.get_control_path}....")
        begin
          # to ensure we have the pid of a non-orphaned control master connection
          cm_pid = control_master_pid
        rescue ::Vagrant::Errors::SSHControlMasterOrphan
          env.ui.info("ALERT: We have rescuing a orphan control master session/process (pid: #{pid})..." )
          cm_pid = pid
        end
        result = control_master_exit rescue
            exists = ::Process.getpgid(cm_pid.to_i) rescue
                env.ui.info("The SSH master control session pid existence is: #{exists}")
        if alive? || exists
          env.ui.info("Killing the SSH master control session (pid: #{cm_pid}) control path: #{env.config.ssh.get_control_path}....")
          if exists.nil? && !alive?
            # We should never see this....
            raise ::Vagrant::Errors::SSHControlMasterNonExistent, {:pid=> cm_pid, :control_path => env.config.ssh.get_control_path}
          else
            ::Process.kill('TERM', cm_pid.to_i)
            env.ui.info("Killed the SSH master control session (pid: #{cm_pid}) control path: #{env.config.ssh.get_control_path}.")
          end
        else
          env.ui.info("Exited the SSH master control session (pid: #{pid||cm_pid}) control path: #{env.config.ssh.get_control_path}.")
        end
      end
      result
    end

    def exit_ssh_session(command_timeout=60, name='', short_name='', tries=5, type='input')
      result = nil
      pause_time = tries * command_timeout
      if alive?
        vagrant_type "echo '#{' EXITING --'*10}'"
        vagrant_type "exit"
        retryable(:tries => tries, :on => ChildProcess::TimeoutError, :sleep => 1.0) do
          env.ui.info("Waiting (up to #{pause_time} sec) to exit SSH #{type.to_s} session (pid: #{pid}) control path: #{env.config.ssh.get_control_path}....")
          result = session.instance_variable_get(("@process").intern).poll_for_exit(command_timeout)
        end
        archived_outputs(short_name, get_process(name).output(aruba_keep_ansi = false))
      else
        # scp sessions likely end up here.
        archived_outputs(short_name, get_process(name).output(aruba_keep_ansi = false))
      end
      if alive?
        env.logger.info("Failed exiting the SSH #{type.to_s} session (pid: #{pid}) control path: #{env.config.ssh.get_control_path}.")
        kill_ssh(name)
      else
        env.ui.info("Exited SSH #{type.to_s} session (pid: #{pid}) control path: #{env.config.ssh.get_control_path}.")
      end
      result
    end

    #Check the SSH input process for 60 minutes. Then kill.
    def exit_and_log( name, command_timeout = 60, tries = 60)
      begin
        short_name = name[0..20] if name
        unless name == @control_master_command
          type = :copy if name[/^scp /]
          type = :input if name[/^ssh /]
          type ||= :other
          exit_ssh_session(command_timeout, name, short_name, tries, type)
        else
          exit_control_master()
        end
      rescue => e
        # Errno::EPIPE for scp commands.
        kill_ssh( name )
        env.ui.info( "End polling for exit. Exception: #{e.inspect}\n#{caller.join('\n')}" )
      end
    end

    # Return the pid (integer) of the SSH control master session.
    def control_master_pid(vagrant_options = build_options)
      cmd = "ssh -O check #{ssh_peculiar_options(vagrant_options)} -o ControlPath=#{env.config.ssh.get_control_path} #{vagrant_options[:username]}@#{vagrant_options[:host]}"
      result = ''
      run(unescape(cmd.strip)) { |process| result = process.stderr(@aruba_keep_ansi) }
      #Success: "Master running (pid=32123)\r\n"
      #Failure: "...No such file or directory..."
      if result[/No such file or directory/,0]
        # We likely have an orphan control master process
        raise ::Vagrant::Errors::SSHControlMasterOrphan, { :control_path => env.config.ssh.get_control_path }
      else
        tmp_pid = result[/\((\d+)\)/,1]
        env.logger.info( "The SSH master control session pid is: #{tmp_pid}" )
        tmp_pid
      end
      tmp_pid
    end

    # Exit from the SSH control master session.
    def control_master_exit(vagrant_options = build_options)
      cmd = "ssh -O exit #{ssh_peculiar_options(vagrant_options)} -o ControlPath=#{env.config.ssh.get_control_path} #{vagrant_options[:username]}@#{vagrant_options[:host]}"
      # The result should be: 'Exit request sent.'
      result = ''
      run(unescape(cmd.strip)) { |process| result = process.stderr(@aruba_keep_ansi) }
      env.logger.info( "The SSH master control session exit result is: #{result.inspect}" )
      result
    end

    # If sending SSH `exit` command did not terminate the SSH session, this process is called and the
    # SSH session pid is killed using posix 'TERM' signal.
    # NOTE: This will always be a fall back method, but one-day (TM),
    def kill_ssh( name )
      change_session( name )
      exists = Process.getpgid( pid.to_i ) rescue
      ::Process.kill( 'TERM', pid.to_i ) unless exists.nil?
      sleep 0.1
      if alive?
        env.logger.info( "ssh")  { "Unsuccessful in killing the SSH input session and process started by the command: #{name}" }
      else
        env.logger.info( "[ssh] Successfully killed the SSH input session and process started by the command: #{name}" )
      end
    end

    # Closes the current Aruba/ChildProcess, which was started by a ssh or `scp` command.issuing 'exit' command
    # by an `ssh` or `scp` command
    def exit
      name = get_name(session)
      if name =~ /^ssh |^scp /
        exit_and_log(name)
      end
    end

    # Indicate if the current SSH session is alive or not.
    # Nil is returned if there the SSH session object/process does not exist or at least has
    # not been assigned to the session variable.
    def alive?
      if session
        session.instance_variable_get(("@process").intern).alive?
      else
        env.logger.info("ssh") { "You queried if the SSH session is alive.  There is no current SSH session." }
        nil
      end
    end

    # Return the current SSH session object.
    def session
      @interactive  # This is an Aruba ivar
    end


    # Change the current SSH session to that launched by the command given as the input argument.
    # The launch/run commands are the name index for processes.
    # NOTE: The SSH session (process) may have been exited ot killed, and a process object will
    # still be returned.  Use the methods `alive?` to establish if the SSH session is alive.
    def change_session(cmd)
      begin
        env.logger.info("ssh") { "The current SSH session is: #{get_name(session)}" }
        proc = get_process(cmd)
        env.logger.info("ssh") { "The current SSH session is changed to: #{cmd}" }
      rescue NoMethodError => e
        if e.message[/undefined method `\[\]' for nil:NilClass/]
          env.logger.info("ssh") { "You tried to change to a SSH session that does not exist, or has been removed. The current session has not been changed. " }
        else
          env.logger.info("ssh") { "You tried to change to a SSH session and an unrecognized error was raised.  Please file a bug report. The current session has not been changed. " }
        end
        proc = session
      rescue
        env.logger.info("ssh") { "You tried to change to a SSH session and an unrecognized error was raised.  Please file a bug report. The current session has not been changed. " }
        proc = session
      ensure
        @interactive = proc
      end
    end

    # Return the name of a given (Aruba) process.
    def get_name(wanted)
      pl = processes.reverse.find{ |_, proc| proc == wanted }
      pl = [] if pl.nil?
      pl.empty? ? nil : pl.flatten[0]
    end

    # Changes the current session to the first alive process that was started by an ssh command.
    def get_connection
      processes.reverse.each do |name, process|
        if name =~ /^ssh / && name != @control_master_command
          env.logger.info("ssh") { "Checking the SSH input session and process started by the command: #{name}" }
          begin
            change_session(name)
            if alive?
              env.logger.info("ssh") { "Found an existing SSH input session." }
              return true
            end
          rescue Errno::EPIPE
            # This should no longer be seen now that we use alive?.
            env.logger.info("ssh")  { "We have already closed the process started by the command: #{name}" }
          ensure
          end
        end
      end
      env.logger.info("ssh") { "Found NO existing SSH input sessions. Distribution: #{env.config.vm.distribution}" }
      false
    end

    # Show the stdout from the current session.
    def show_connection_output
      name = get_name(session)
      processes.each do |n, process|
        if n == name
          (env.ui.info("#{process.output(aruba_keep_ansi = false)}") ) unless name.nil?
        end
        parse_last_remote_status([name].flatten, '<unknown>', build_options)
      end

    end

    # Show the stdout from the all SSH sessions.
    def show_all_connection_output
      env.ui.info(archived_outputs) if archived_outputs && archived_outputs.size > 0
    end

    # Executes a given command on the SSH session (ChildProcess+Aruba::Api object) using `sudo` and
    # blocks until the command completes, _and_ ssh session exits. This takes the same parameters
    # as {#exec!}. That is, the command can be an array of commands, which will be placed into the
    # same script.
    #
    def sudo!(commands, options=nil, &block)
      result = nil
      begin
        exceptions = [ChildProcess::TimeoutError, IOError, ::Vagrant::Errors::SSHUnavailable]
        retryable(:tries => 5, :on => exceptions, :sleep => 1.0) do
            case env.config.vm.distribution
              when :ubuntu
                cmd = "sudo su -c 'export TERM=vt100"
                [commands].flatten.each { |command| cmd += "; #{command}" }
                cmd += "'" # we don't silence the last command with ;
                env.logger.info("ssh") { vagrant_remote_cmd( cmd ) }
                vagrant_type( vagrant_remote_cmd( cmd ) )
                result = parse_last_remote_status(get_name(session), cmd, options)
              else
                vagrant_type( vagrant_remote_cmd( "sudo -H #{env.config.ssh.shell} -l" ) )
                vagrant_type( vagrant_remote_cmd( "export TERM=vt100" ) )
                [commands].flatten.each do |command|
                  vagrant_type( vagrant_remote_cmd( command ) )
                  result = parse_last_remote_status(get_name(session), command, options)
                end
                vagrant_type( vagrant_remote_cmd( "exit" ) )
             end
          return result == 0 ? true : false
        end
      rescue Errno::EPIPE
        execute
        retry
      rescue => e
        env.logger.info("ssh") { e.inspect }
        exit_all
      end
    end

    # Executes given commands on the SSH session (ChildProcess+Aruba::Api object) and blocks until
    # The commands can be an array of commands,
    #
    # TODO: When multiplexed SSH connections are burned in - replace the retry guard with if alive? else execute
    # Rather check alive?
    def exec!(commands, options=nil, &block)
      result = nil
      begin
        retryable(:tries => 5, :on => [ChildProcess::TimeoutError, IOError, ::Vagrant::Errors::SSHUnavailable], :sleep => 1.0) do
          [commands].flatten.each do |command|
            vagrant_type(vagrant_remote_cmd(command))
            result = parse_last_remote_status(get_name(session), command, options)
            env.logger.info("ssh") { "command: #{vagrant_remote_cmd(command)} result: #{result}" }
          end
          #return yield(self, last_exit_status, all_output) if block_given?
          return result == 0 ? true : false
        end
      rescue Errno::EPIPE
        execute
        retry
      end
    end

    # Sets up the channel callbacks to properly check exit statuses and
    # callback on stdout/stderr. returns the int printed by the last `echo $?`
    # run on the remote shell
    #TODO Implement something like this method, but using Arubas' stdout/stderr assert methods
    def parse_last_remote_status(session_names, command, options)
      remote_status = nil
      stdo = nil
      stde = nil

      # Output last remote exit status information to the block.
      # The method all_stdout stops all processes.
      [session_names].flatten.each do |ssh_sess|
        begin
          stdo = output_from(ssh_sess)
        rescue => e
          env.logger.info("ssh parse exit status rescued: #{e.inspect}")
        end

        if stdo.nil?
          # Hmmm possibly the SSH control master session, and at connection startup
          env.logger.info("ssh") { "Getting master connection output." }
          stdo = ''  if env.config.ssh.master_connection && @control_master_command
        end
        env.logger.info("ssh") { "Last output line: #{stdo.split.last}" }

        exit_status_array = stdo.split.keep_if{|elem| elem[/vsrces/]}
        if exit_status_array.empty?
          # Hmmm possibly only the SSH control master session, and at connection startup

        else
          remote_status = exit_status_array.last[/vsrces:(\d+)/,1]
          env.logger.info("ssh parsed exit status listing: #{remote_status.inspect}")
          check_exit_status(remote_status.to_i, ssh_sess, command, options, stdo, stde)
          remote_status = remote_status.to_i
        end
      end
      remote_status
    end

    # Checks for an erroneous exit status. Raise exception if found.
    def check_exit_status(exit_status, session_name, command, options={}, output='', error='')

      if exit_status != 0
        output ||= '[no output]'
        options = {
          :_error_class => Errors::VagrantError,
          :_key => :ssh_bad_exit_status,
          :session_name => [session_name].flatten.join("\n"),
          :command => [command].flatten.join("\n"),
          :output => output,
          :error => error
        }.merge(options || {})

        raise options[:_error_class], options
      end
    end

    private


  end
end
