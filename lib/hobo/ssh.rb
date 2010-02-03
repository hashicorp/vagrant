module Hobo
  class SSH
    SCRIPT = File.join(File.dirname(__FILE__), '..', '..', 'script', 'hobo-ssh-expect.sh')

    class << self
      def connect(opts={})
        options = {}
        [:host, :pass, :uname].each do |param|
          options[param] = opts[param] || Hobo.config.ssh.send(param)
        end

        # The port is special
        options[:port] = opts[:port] || Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]

        Kernel.exec "#{SCRIPT} #{options[:uname]} #{options[:pass]} #{options[:host]} #{options[:port]}".strip
      end

      def execute
        port = Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]
        Net::SSH.start("localhost", Hobo.config[:ssh][:uname], :port => port, :password => Hobo.config[:ssh][:pass]) do |ssh|
          yield ssh
        end
      end

      def up?
        port = Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]
        Ping.pingecho "localhost", 1, port
      end
    end
  end
end
