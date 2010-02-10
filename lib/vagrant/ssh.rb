module Vagrant
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'vagrant-ssh-expect.sh')

    class << self
      def connect(opts={})
        options = {}
        [:host, :password, :username].each do |param|
          options[param] = opts[param] || Vagrant.config.ssh.send(param)
        end

        # The port is special
        options[:port] = opts[:port] || Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]

        Kernel.exec "#{SCRIPT} #{options[:username]} #{options[:password]} #{options[:host]} #{options[:port]}".strip
      end

      def execute
        port = Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]
        Net::SSH.start(Vagrant.config.ssh.host, Vagrant.config[:ssh][:username], :port => port, :password => Vagrant.config[:ssh][:password]) do |ssh|
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
        port = Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]
        Net::SSH.start(Vagrant.config.ssh.host, Vagrant.config.ssh.username, :port => port, :password => Vagrant.config.ssh.password, :timeout => 5) do |ssh|
          return true
        end

        false
      rescue Errno::ECONNREFUSED
        false
      end
    end
  end
end
