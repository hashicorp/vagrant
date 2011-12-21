require 'log4r'
require 'net/ssh'
require 'net/scp'

module Vagrant
  # Manages SSH access to a specific environment. Allows an environment to
  # replace the process with SSH itself, run a specific set of commands,
  # upload files, or even check if a host is up.
  class SSH
    # Autoload this guy because he is really only used in one location
    # and not for every Vagrant command.
    autoload :Session, 'vagrant/ssh/session'

    include Util::Retryable
    include Util::SafeExec

    def initialize(vm)
      @vm     = vm
      @logger = Log4r::Logger.new("vagrant::ssh")
    end

    # Connects to the environment's virtual machine, replacing the ruby
    # process with an SSH process. This method optionally takes a hash
    # of options which override the configuration values.
    def connect(opts={})
      if Util::Platform.windows?
        raise Errors::SSHUnavailableWindows, :key_path => private_key_path,
                                             :ssh_port => port(opts)
      end

      raise Errors::SSHUnavailable if !Kernel.system("which ssh > /dev/null 2>&1")

      options = {}
      options[:port] = port(opts)
      options[:private_key_path] = private_key_path
      [:host, :username].each do |param|
        options[param] = opts[param] || @vm.config.ssh.send(param)
      end

      check_key_permissions(options[:private_key_path])

      # Command line options
      command_options = ["-p #{options[:port]}", "-o UserKnownHostsFile=/dev/null",
                         "-o StrictHostKeyChecking=no", "-o IdentitiesOnly=yes",
                         "-i #{options[:private_key_path]}", "-o LogLevel=ERROR"]
      command_options << "-o ForwardAgent=yes" if @vm.config.ssh.forward_agent

      if @vm.config.ssh.forward_x11
        # Both are required so that no warnings are shown regarding X11
        command_options << "-o ForwardX11=yes"
        command_options << "-o ForwardX11Trusted=yes"
      end

      command = "ssh #{command_options.join(" ")} #{options[:username]}@#{options[:host]}".strip
      @logger.info("Invoking SSH: #{command}")
      safe_exec(command)
    end

    # Opens an SSH connection to this environment's virtual machine and yields
    # a Net::SSH object which can be used to execute remote commands.
    def execute(opts={})
      # Check the key permissions to avoid SSH hangs
      check_key_permissions(private_key_path)

      # Merge in any additional options
      opts = opts.dup
      opts[:forward_agent] = true if @vm.config.ssh.forward_agent
      opts[:port] ||= port

      @logger.info("Connecting to SSH: #{@vm.config.ssh.host} #{opts[:port]}")

      # The exceptions which are acceptable to retry on during
      # attempts to connect to SSH
      exceptions = [Errno::ECONNREFUSED, Net::SSH::Disconnect]

      # Connect to SSH and gather the session
      session = retryable(:tries => @vm.config.ssh.max_tries, :on => exceptions) do
        connection = Net::SSH.start(@vm.config.ssh.host,
                                    @vm.config.ssh.username,
                                    opts.merge( :keys => [private_key_path],
                                                :keys_only => true,
                                                :user_known_hosts_file => [],
                                                :paranoid => false,
                                                :config => false))

        sleep 4 # Hacky but helps with issue #391, #455, etc.

        SSH::Session.new(connection, @vm)
      end

      # Yield our session for executing
      return yield session if block_given?
    rescue Errno::ECONNREFUSED
      raise Errors::SSHConnectionRefused
    end

    # Uploads a file from `from` to `to`. `from` is expected to be a filename
    # or StringIO, and `to` is expected to be a path. This method simply forwards
    # the arguments to `Net::SCP#upload!` so view that for more information.
    def upload!(from, to)
      retryable(:tries => 5, :on => IOError) do
        execute do |ssh|
          scp = Net::SCP.new(ssh.session)
          scp.upload!(from, to)
        end
      end
    rescue Net::SCP::Error => e
      # If we get the exit code of 127, then this means SCP is unavailable.
      raise Errors::SCPUnavailable if e.message =~ /\(127\)/

      # Otherwise, just raise the error up
      raise
    end

    # Checks if this environment's machine is up (i.e. responding to SSH).
    #
    # @return [Boolean]
    def up?
      @logger.debug("Checking whether SSH is up")

      # We have to determine the port outside of the block since it uses
      # API calls which can only be used from the main thread in JRuby on
      # Windows
      ssh_port = port

      require 'timeout'
      Timeout.timeout(@vm.config.ssh.timeout) do
        execute(:timeout => @vm.config.ssh.timeout, :port => ssh_port) { |ssh| }
      end

      @logger.info("SSH is up!")
      true
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect,
           Errors::SSHConnectionRefused => e
      @logger.info("SSH not up: #{e.inspect}")
      return false
    end

    # Checks the file permissions for the private key, resetting them
    # if needed, or on failure erroring.
    def check_key_permissions(key_path)
      # Windows systems don't have this issue
      return if Util::Platform.windows?

      @logger.info("Checking key permissions: #{key_path}")

      stat = File.stat(key_path)

      if stat.owned? && file_perms(key_path) != "600"
        @logger.info("Attempting to correct key permissions to 0600")

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
      return @vm.config.ssh.port if @vm.config.ssh.port

      # Check if we have an SSH forwarded port
      pnum_by_name = nil
      pnum_by_destination = nil
      @vm.driver.read_forwarded_ports.each do |_, name, hostport, guestport|
        # Record the forwarded port if we find it by name
        if name == @vm.config.ssh.forwarded_port_key
          pnum_by_name = hostport
        end

        if guestport == @vm.config.ssh.forwarded_port_destination
          pnum_by_destination = hostport
        end

        # pnum_by_name is what we're looking for here, so break early
        # if we have it.
        break if pnum_by_name
      end

      return pnum_by_name if pnum_by_name
      return pnum_by_destination if pnum_by_destination

      # This should NEVER happen.
      raise Errors::SSHPortNotDetected
    end

    def private_key_path
      path = @vm.config.ssh.private_key_path || @vm.env.default_private_key_path
      File.expand_path(path, @vm.env.root_path)
    end
  end
end
