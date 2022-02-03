require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    class Client
      class Guest < Client
        include CapabilityPlatform

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def parent_func
          spec = client.parent_spec(Empty.new)
          cb = proc do |args|
            client.parent(args).parent
          end
          [spec, cb]
        end

        # @param [Vagrant::Machine]
        # @return [Boolean]
        def detect(machine)
          req = SDK::FuncSpec::Args.new(
            args: [SDK::FuncSpec::Value.new(
                name: "",
                type: "hashicorp.vagrant.sdk.Args.Target.Machine",
                value: Google::Protobuf::Any.pack(machine.to_proto)
            )]
          )
          res = client.detect(req)
          res.detected
        end

        # @return [String] parents
        def parent
          run_func
        end
      end
    end
  end
end
