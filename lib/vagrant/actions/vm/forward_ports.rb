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
                  raise ActionException.new(:vm_port_collision, :name => name, :hostport => fp.hostport.to_s, :guestport => options[:guestport].to_s, :instance => options[:instance])
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
            adapter = options[:instance]

            # Assuming the only reason to establish port forwarding is because the VM is using Virtualbox NAT networking.
            # Host-only or Bridged networking don't require port-forwarding and establishing forwarded ports on these
            # attachment types has uncertain behaviour.
            if @runner.vm.network_adapters[adapter].attachment_type == :nat
               logger.info "Forwarding \"#{name}\": #{options[:guestport]} on adapter \##{adapter+1} => #{options[:hostport]}"
               port = VirtualBox::ForwardedPort.new
               port.name = name
               port.hostport = options[:hostport]
               port.guestport = options[:guestport]
               port.instance = adapter
               @runner.vm.forwarded_ports << port
            else
              logger.info "VirtualBox adapter \##{adapter+1} not configured as \"NAT\"."
              logger.info "Skipped port forwarding \"#{name}\": #{options[:guestport]} on adapter\##{adapter+1} => #{options[:hostport]}"
            end
          end

          @runner.vm.save
        end
      end
    end
  end
end
