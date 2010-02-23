module Vagrant
  module Actions
    module VM
      class ForwardPorts < Base
        def execute!
          clear
          forward_ports
        end

        def clear
          logger.info "Deleting any previously set forwarded ports..."
          @runner.vm.forwarded_ports.collect { |p| p.destroy(true) }
        end

        def forward_ports
          logger.info "Forwarding ports..."

          Vagrant.config.vm.forwarded_ports.each do |name, options|
            logger.info "Forwarding \"#{name}\": #{options[:guestport]} => #{options[:hostport]}"
            port = VirtualBox::ForwardedPort.new
            port.name = name
            port.hostport = options[:hostport]
            port.guestport = options[:guestport]
            @runner.vm.forwarded_ports << port
          end

          @runner.vm.save(true)
        end
      end
    end
  end
end
