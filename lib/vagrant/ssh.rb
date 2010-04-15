module Vagrant
  # Manages SSH access to a specific environment. Allows an environment to
  # replace the process with SSH itself, run a specific set of commands,
  # upload files, or even check if a host is up.
  class SSH
    include Vagrant::Util

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
        error_and_exit(:ssh_unavailable_windows,
                       :key_path => env.config.ssh.private_key_path,
                       :ssh_port => port(opts))
      end

      options = {}
      [:host, :username, :private_key_path].each do |param|
        options[param] = opts[param] || env.config.ssh.send(param)
      end

      check_key_permissions(options[:private_key_path])

      # Some hackery going on here. On Mac OS X Leopard (10.5), exec fails
      # (GH-51). As a workaround, we fork and wait. On all other platforms,
      # we simply exec.
      pid = nil
      pid = fork if Util::Platform.leopard?
      Kernel.exec "ssh -p #{port(opts)} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{options[:private_key_path]} #{options[:username]}@#{options[:host]}".strip if pid.nil?
      Process.wait(pid) if pid
    end

    # Opens an SSH connection to this environment's virtual machine and yields
    # a Net::SSH object which can be used to execute remote commands.
    def execute(opts={})
      Net::SSH.start(env.config.ssh.host,
                     env.config[:ssh][:username],
                     opts.merge( :port => port,
                                 :keys => [env.config.ssh.private_key_path])) do |ssh|
        yield ssh
      end
    end

    # Uploads a file from `from` to `to`. `from` is expected to be a filename
    # or StringIO, and `to` is expected to be a path. This method simply forwards
    # the arguments to `Net::SCP#upload!` so view that for more information.
    def upload!(from, to)
      execute do |ssh|
        scp = Net::SCP.new(ssh)
        scp.upload!(from, to)
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
      error_and_exit(:vm_ssh_auth_failed)
    end

    # Checks the file permissions for the private key, resetting them
    # if needed, or on failure erroring.
    def check_key_permissions(key_path)
      # TODO: This only works on unix based systems for now. Windows
      # systems will need to be investigated further.
      stat = File.stat(key_path)

      if stat.owned? && file_perms(key_path) != "600"
        logger.info "Permissions on private key incorrect, fixing..."
        File.chmod(0600, key_path)

        error_and_exit(:ssh_bad_permissions, :key_path => key_path) if file_perms(key_path) != "600"
      end
    rescue Errno::EPERM
      # This shouldn't happen since we verify we own the file, but just
      # in case.
      error_and_exit(:ssh_bad_permissions, :key_path => key_path)
    end

    # Returns the file permissions of a given file. This is fairly unix specific
    # and probably doesn't belong in this class. Will be refactored out later.
    def file_perms(path)
      perms = sprintf("%o", File.stat(path).mode)
      perms.reverse[0..2].reverse
    end

    # Returns the port which is either given in the options hash or taken from
    # the config by finding it in the forwarded ports hash based on the
    # `config.ssh.forwarded_port_key`
    def port(opts={})
      opts[:port] || env.config.vm.forwarded_ports[env.config.ssh.forwarded_port_key][:hostport]
    end
  end
end
