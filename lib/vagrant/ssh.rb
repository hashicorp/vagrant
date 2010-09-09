require 'net/ssh'
require 'net/scp'
require 'mario'

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
        raise Errors::SSHUnavailableWindows.new(:key_path => env.config.ssh.private_key_path,
                                                :ssh_port => port(opts))
      end

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

      retryable(:tries => 5, :on => Errno::ECONNREFUSED) do
        Net::SSH.start(env.config.ssh.host,
                       env.config.ssh.username,
                       opts.merge( :port => port,
                                   :keys => [env.config.ssh.private_key_path],
                                   :user_known_hosts_file => [],
                                   :paranoid => false,
                                   :config => false)) do |ssh|
          yield SSH::Session.new(ssh)
        end
      end
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
      check_thread = Thread.new do
        begin
          Thread.current[:result] = false
          execute(:timeout => env.config.ssh.timeout) do |ssh|
            Thread.current[:result] = true
          end
        rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
          # False, its defaulted above
        end
      end

      check_thread.join(env.config.ssh.timeout)
      return check_thread[:result]
    rescue Net::SSH::AuthenticationFailed
      raise Errors::SSHAuthenticationFailed.new
    end

    # Checks the file permissions for the private key, resetting them
    # if needed, or on failure erroring.
    def check_key_permissions(key_path)
      # Windows systems don't have this issue
      return if Mario::Platform.windows?

      stat = File.stat(key_path)

      if stat.owned? && file_perms(key_path) != "600"
        File.chmod(0600, key_path)

        raise Errors::SSHKeyBadPermissions.new(:key_path => key_path) if file_perms(key_path) != "600"
      end
    rescue Errno::EPERM
      # This shouldn't happen since we verify we own the file, but just
      # in case.
      raise Errors::SSHKeyBadPermissions.new(:key_path => key_path)
    end

    # Returns the file permissions of a given file. This is fairly unix specific
    # and probably doesn't belong in this class. Will be refactored out later.
    def file_perms(path)
      perms = sprintf("%o", File.stat(path).mode)
      perms.reverse[0..2].reverse
    end

    # Returns the port which is either given in the options hash or taken from
    # the config by finding it in the forwarded ports hash based on the
    # `config.ssh.forwarded_port_key` or use the default port given by `config.ssh.port`
    # when port forwarding isn't used.
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

      # Fall back to the default
      return env.config.ssh.port
    end
  end

  class SSH
    # A helper class which wraps around `Net::SSH::Connection::Session`
    # in order to provide basic command error checking while still
    # providing access to the actual session object.
    class Session
      include Util::Retryable

      attr_reader :session

      def initialize(session)
        @session = session
      end

      # Executes a given command on the SSH session and blocks until
      # the command completes. This is an almost line for line copy of
      # the actual `exec!` implementation, except that this
      # implementation also reports `:exit_status` to the block if given.
      def exec!(command, options=nil, &block)
        options = {
          :error_check => true
        }.merge(options || {})

        block ||= Proc.new do |ch, type, data|
          check_exit_status(data, command, options) if type == :exit_status && options[:error_check]

          ch[:result] ||= ""
          ch[:result] << data if [:stdout, :stderr].include?(type)
        end

        retryable(:tries => 5, :on => IOError, :sleep => 0.5) do
          metach = session.open_channel do |channel|
            channel.exec(command) do |ch, success|
              raise "could not execute command: #{command.inspect}" unless success

              # Output stdout data to the block
              channel.on_data do |ch2, data|
                block.call(ch2, :stdout, data)
              end

              # Output stderr data to the block
              channel.on_extended_data do |ch2, type, data|
                block.call(ch2, :stderr, data)
              end

              # Output exit status information to the block
              channel.on_request("exit-status") do |ch2, data|
                block.call(ch2, :exit_status, data.read_long)
              end
            end
          end

          metach.wait
          metach[:result]
        end
      end

      # Checks for an erroroneous exit status and raises an exception
      # if so.
      def check_exit_status(exit_status, command, options=nil)
        if exit_status != 0
          options = {
            :_error_class => Errors::VagrantError,
            :_key => :ssh_bad_exit_status,
            :command => command
          }.merge(options || {})

          raise options[:_error_class].new(options)
        end
      end
    end
  end
end
