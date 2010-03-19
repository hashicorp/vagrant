module Vagrant
  class SSH
    include Vagrant::Util

    class << self
      def connect(opts={})
        options = {}
        [:host, :username, :private_key_path].each do |param|
          options[param] = opts[param] || Vagrant.config.ssh.send(param)
        end

        check_key_permissions(options[:private_key_path])
        Kernel.exec "ssh -p #{port(opts)} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i #{options[:private_key_path]} #{options[:username]}@#{options[:host]}".strip
      end

      def execute(opts={})
        Net::SSH.start(Vagrant.config.ssh.host,
                       Vagrant.config[:ssh][:username],
                       opts.merge( :port => port,
                                   :keys => [Vagrant.config.ssh.private_key_path])) do |ssh|
          yield ssh
        end
      end

      def upload!(from, to)
        execute do |ssh|
          scp = Net::SCP.new(ssh)
          scp.upload!(from, to)
        end
      end

      def up?
        check_thread = Thread.new do
          begin
            Thread.current[:result] = false
            execute(:timeout => Vagrant.config.ssh.timeout) do |ssh|
              Thread.current[:result] = true
            end
          rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
            # False, its defaulted above
          end
        end

        check_thread.join(Vagrant.config.ssh.timeout)
        return check_thread[:result]
      rescue Net::SSH::AuthenticationFailed
        error_and_exit(:vm_ssh_auth_failed)
      end

      def port(opts={})
        opts[:port] || Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]
      end

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

      def file_perms(path)
        perms = sprintf("%o", File.stat(path).mode)
        perms.reverse[0..2].reverse
      end
    end
  end
end
