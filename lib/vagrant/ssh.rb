require 'timeout'
require 'net/ssh'
require 'net/scp'
require 'mario'

require 'vagrant/ssh/session'

module Vagrant
  # Manages SSH access to a specific environment. Allows an environment to
  # replace the process with SSH itself, run a specific set of commands,
  # upload files, or even check if a host is up.
  class SSH
    include Util::Retryable

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
      if Mario::Platform.windows?
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
                         "-i #{options[:private_key_path]}"]
      command_options << "-o ForwardAgent=yes" if env.config.ssh.forward_agent
      command_options << "-o ForwardX11=yes" if env.config.ssh.forward_x11

      # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
      # (GH-51). As a workaround, we fork and wait. On all other platforms,
      # we simply exec.
      pid = nil
      pid = fork if Util::Platform.leopard? || Util::Platform.tiger?
      Kernel.exec "ssh #{command_options.join(" ")} #{options[:username]}@#{options[:host]}".strip if pid.nil?
      Process.wait(pid) if pid
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

      retryable(:tries => 5, :on => Errno::ECONNREFUSED) do
        Net::SSH.start(env.config.ssh.host,
                       env.config.ssh.username,
                       opts.merge( :keys => [env.config.ssh.private_key_path],
                                   :user_known_hosts_file => [],
                                   :paranoid => false,
                                   :config => false)) do |ssh|
          yield SSH::Session.new(ssh)
        end
      end
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

      Timeout.timeout(env.config.ssh.timeout) do
        execute(:timeout => env.config.ssh.timeout,
                :port => ssh_port) { |ssh| }
      end

      true
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed
    rescue Timeout::Error, Errno::ECONNREFUSED, Net::SSH::Disconnect,
           Errors::SSHConnectionRefused, Net::SSH::AuthenticationFailed
      return false
    end

    # Checks the file permissions for the private key, resetting them
    # if needed, or on failure erroring.
    def check_key_permissions(key_path)
      # Windows systems don't have this issue
      return if Mario::Platform.windows?

      stat = File.stat(key_path)

      if stat.owned? && file_perms(key_path) != "600"
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
      pnum = opts[:port]
      return pnum if pnum

      # Check if we have an SSH forwarded port
      pnum = nil
      env.vm.vm.network_adapters.each do |na|
        pnum = na.nat_driver.forwarded_ports.detect do |fp|
          fp.name == env.config.ssh.forwarded_port_key
        end

        break if pnum
      end

      return pnum.hostport if pnum

      # This should NEVER happen.
      raise Errors::SSHPortNotDetected
    end
  end
end
