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

          config.vm.networks.each do |type, args|
            if type == :forwarded_port
              guest_port = args[0]
              host_port  = args[1]
              options    = args[2] || {}
              options    = scoped_hash_override(options, :virtualbox)
              id         = options[:id] ||
                "#{guest_port.to_s(32)}-#{host_port.to_s(32)}"

              mappings[host_port] =
                Model::ForwardedPort.new(id, host_port, guest_port, options)
            end
          end

          mappings.values
        end
      end
    end
  end
end
