require "vagrant/util/scoped_hash_override"

module VagrantPlugins
  module ProviderVirtualBox
    module Util
      module CompileForwardedPorts
        include Vagrant::Util::ScopedHashOverride

        # This method compiles the forwarded ports into {ForwardedPort}
        # models.
        def compile_forwarded_ports(config)
          mappings = {}

          config.vm.networks.each do |type, options|
            if type == :forwarded_port
              guest_port = options[:guest]
              host_port  = options[:host]
              host_ip    = options[:host_ip]
              protocol   = options[:protocol] || "tcp"
              options    = scoped_hash_override(options, :virtualbox)
              id         = options[:id]

              # If the forwarded port was marked as disabled, ignore.
              next if options[:disabled]
              
              if id == "ssh"
                guest_port = config.ssh.guest_port
              end

              key = "#{host_ip}#{protocol}#{host_port}"
              mappings[key] =
                Model::ForwardedPort.new(id, host_port, guest_port, options)
            end
          end

          mappings.values
        end
      end
    end
  end
end
