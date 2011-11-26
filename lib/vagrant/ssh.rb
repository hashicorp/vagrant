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

    # Reference back up to the environment which this SSH object belongs
    # to
    attr_accessor :env

    def initialize(environment)
      @env = environment
    end

    # Connects to the environment's virtual machine, replacing the ruby
    # process with an SSH process. This method optionally takes a hash
    # of options which override the configuration values.
    def connect(opts={})
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

      # Command line options
      command_options = ["-p #{options[:port]}", "-o UserKnownHostsFile=/dev/null",
                         "-o StrictHostKeyChecking=no", "-o IdentitiesOnly=yes",
                         "-i #{options[:private_key_path]}", "-o LogLevel=ERROR"]
      command_options << "-o ForwardAgent=yes" if env.config.ssh.forward_agent

      if env.config.ssh.forward_x11
        # Both are required so that no warnings are shown regarding X11
        command_options << "-o ForwardX11=yes"
        command_options << "-o ForwardX11Trusted=yes"
      end

      command = "ssh #{command_options.join(" ")} #{options[:username]}@#{options[:host]}".strip
      env.logger.info("ssh") { "Invoking SSH: #{command}" }
      safe_exec(command)
    end

    # Opens an SSH connection to this environment's virtual machine and yields
    # a Net::SSH object which can be used to execute remote commands.
    def execute(opts={})
      # Check the key permissions to avoid SSH hangs
      check_key_permissions(env.config.ssh.private_key_path)

      # Merge in any additional options
      opts = opts.dup
      opts[:forward_agent] = true if env.config.ssh.forward_agent
      opts[:port] ||= port

      env.logger.info("ssh") { "Connecting to SSH: #{env.config.ssh.host} #{opts[:port]}" }

      # The exceptions which are acceptable to retry on during
      # attempts to connect to SSH
      exceptions = [Errno::ECONNREFUSED, Net::SSH::Disconnect]

      # Connect to SSH and gather the session
      session = retryable(:tries => env.config.ssh.max_tries, :on => exceptions) do
        connection = Net::SSH.start(env.config.ssh.host,
                                    env.config.ssh.username,
                                    opts.merge( :keys => [env.config.ssh.private_key_path],
                                                :keys_only => true,
                                                :user_known_hosts_file => [],
                                                :paranoid => false,
                                                :config => false))
        SSH::Session.new(connection, env)
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
    end

    # Checks if this environment's machine is up (i.e. responding to SSH).
    #
    # @return [Boolean]
    def up?
      # We have to determine the port outside of the block since it uses
      # API calls which can only be used from the main thread in JRuby on
      # Windows
      ssh_port = port

      require 'timeout'
      Timeout.timeout(env.config.ssh.timeout) do
        execute(:timeout => env.config.ssh.timeout, :port => ssh_port) do |ssh|
          # We run a basic command to test that the shell is up and
          # ready to receive commands. Only then is our SSH connection
          # truly "up"
          return ssh.exec!("echo hello") == "hello\n"
        end
      end

      false
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect,
           Errors::SSHConnectionRefused
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
  end
end
