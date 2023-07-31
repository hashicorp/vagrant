# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Provisioner < Client
        prepend Util::ClientSetup
        prepend Util::HasLogger
        include Util::HasSeeds::Client

        def cleanup_func
          spec = client.cleanup_spec(Empty.new)
          cb = proc do |args|
            client.cleanup(args)
          end
          [spec, cb]
        end

        def cleanup(machine, config)
          run_func(machine, config)
        end

        def configure_func
          spec = client.configure_spec(Empty.new)
          cb = proc do |args|
            client.configure(args)
          end
          [spec, cb]
        end

        def configure(machine, config, root_config)
          run_func(machine, config, root_config, {})
        end

        def provision_func
          spec = client.provision_spec(Empty.new)
          cb = proc do |args|
            client.provision(args)
          end
          [spec, cb]
        end

        def provision(machine, config)
          run_func(machine, config)
        end
      end
    end
  end
end
