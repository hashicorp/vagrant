module Vagrant
  module Actions
    module VM
      class ForwardPorts < Base
        def prepare
          VirtualBox::VM.all.each do |vm|
            next if !vm.running? || vm.uuid == @runner.uuid

            vm.forwarded_ports.each do |fp|
              @runner.env.config.vm.forwarded_ports.each do |name, options|
                if fp.hostport.to_s == options[:hostport].to_s
                  raise ActionException.new(:vm_port_collision, :name => name, :hostport => fp.hostport.to_s, :guestport => options[:guestport].to_s)
                end
              end
            end
          end
        end

        def execute!
          clear
          forward_ports
        end

        def clear
          logger.info "Deleting any previously set forwarded ports..."
          @runner.vm.forwarded_ports.collect { |p| p.destroy }
        end

        def forward_ports
          logger.info "Forwarding ports..."

          @runner.env.config.vm.forwarded_ports.each do |name, options|
            logger.info "Forwarding \"#{name}\": #{options[:guestport]} => #{options[:hostport]}"
            port = VirtualBox::ForwardedPort.new
            port.name = name
            port.hostport = options[:hostport]
            port.guestport = options[:guestport]
            @runner.vm.forwarded_ports << port
          end

          @runner.vm.save
        end
      end
    end
  end
end
