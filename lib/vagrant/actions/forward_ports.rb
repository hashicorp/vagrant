module Vagrant
  module Actions
    class ForwardPorts < Base
      def execute!
        logger.info "Forwarding ports..."

        Vagrant.config.vm.forwarded_ports.each do |name, options|
          logger.info "Forwarding \"#{name}\": #{options[:guestport]} => #{options[:hostport]}"
          port = VirtualBox::ForwardedPort.new
          port.name = name
          port.hostport = options[:hostport]
          port.guestport = options[:guestport]
          @vm.forwarded_ports << port
        end

        @vm.save(true)
      end
    end
  end
end
