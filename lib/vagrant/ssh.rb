module Vagrant
  class SSH
    include Vagrant::Util

    class << self
      def connect(opts={})
        options = {}
        [:host, :username, :private_key_path].each do |param|
          options[param] = opts[param] || Vagrant.config.ssh.send(param)
        end

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
        error_and_exit(<<-msg)
SSH authentication failed! While this could be due to a variety of reasons,
the two most common are: private key path is incorrect or you're using a box
which was built for Vagrant 0.1.x.

Vagrant 0.2.x dropped support for password-based authentication. If you're
tring to `vagrant up` a box which does not support Vagrant's private/public
keypair, then this error will be raised. To resolve this, read the guide
on converting base boxes from password-based to keypairs here:

http://vagrantup.com/docs/converting_password_to_key_ssh.html

If the box was built for 0.2.x and contains a custom public key, perhaps
the path to the private key is incorrect. Check your `config.ssh.private_key_path`.
msg
      end

      def port(opts={})
        opts[:port] || Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]
      end
    end
  end
end
