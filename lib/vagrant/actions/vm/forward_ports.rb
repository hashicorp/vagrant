module Vagrant
  module Actions
    module VM
      class ForwardPorts < Base
        def prepare
          ActiveList.vms.each do |vagrant_vm|
            vm = vagrant_vm.vm
            next unless vm.running?

            vm.forwarded_ports.each do |fp|
              Vagrant.config.vm.forwarded_ports.each do |name, options|
                if fp.hostport.to_s == options[:hostport].to_s
                  raise ActionException.new(<<-msg)
Vagrant cannot forward the specified ports on this VM, since they
would collide with another Vagrant-managed virtual machine's forwarded
ports! The "#{name}" forwarded port (#{fp.hostport}) is already in use on the host
machine.

To fix this, modify your current projects Vagrantfile to use another
port. Example, where '1234' would be replaced by a unique host port:

config.vm.forward_port("#{name}", #{options[:guestport]}, 1234)
msg
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
