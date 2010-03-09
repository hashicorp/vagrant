module Vagrant
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'vagrant-ssh-expect.sh')

    class << self
      def connect(opts={})
        options = {}
        [:host, :password, :username].each do |param|
          options[param] = opts[param] || Vagrant.config.ssh.send(param)
        end

        Kernel.exec "#{SCRIPT} #{options[:username]} #{options[:password]} #{options[:host]} #{port(opts)}".strip
      end

      def execute
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
        check_thread = Thread.new do
          begin
            Thread.current[:result] = false
            Net::SSH.start(Vagrant.config.ssh.host, Vagrant.config.ssh.username, :port => port, :password => Vagrant.config.ssh.password, :timeout => 5) do |ssh|
              Thread.current[:result] = true
            end
          rescue Errno::ECONNREFUSED, Net::SSH::Disconnect
            # False, its defaulted above
          end
        end

        check_thread.join(5)
        return check_thread[:result]
      end

      def port(opts={})
        opts[:port] || Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport]
      end
    end
  end
end
