require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class Guest

        extend Util::Connector

        attr_reader :broker
        attr_reader :client
        attr_reader :proto

        def initialize(conn, proto, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::guest")
          @logger.debug("connecting to guest service on #{conn}")
          @client = SDK::GuestService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
          @proto = proto
        end

        def self.load(raw_guest, broker:)
          g = raw_guest.is_a?(String) ? SDK::Args::Guest.decode(raw_guest) : raw_guest
          self.new(connect(proto: g, broker: broker), g, broker)
        end

        # @return [<String>] parents
        def parents
          @logger.debug("getting parents")
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.parents(req)
          @logger.debug("got parents #{res}")
          res.parents
        end

        # @param [Symbol] cap_name Capability name
        # @return [Boolean]
        def capability?(cap_name)
          @logger.debug("checking for capability #{cap_name}")
          val = SDK::Args::NamedCapability.new(Capability: cap_name.to_s)
          req = SDK::FuncSpec::Args.new(
            args: [SDK::FuncSpec::Value.new(
                name: "", 
                type: "hashicorp.vagrant.sdk.Args.NamedCapability", 
                value: Google::Protobuf::Any.pack(val)
            )]
          )
          res = client.has_capability(req)
          @logger.debug("got result #{res}")

          res.has_capability
        end

        # @param [Symbol] cap_name Name of the capability
        def capability(cap_name, *args)
          arg_protos = []
          args.each do |a|
            if a.class.ancestors.include?(Google::Protobuf::MessageExts)
              val = a
            else
              val = Google::Protobuf::Value.new
              val.from_ruby(a)
            end
            arg_protos << SDK::FuncSpec::Value.new(
              name: "", 
              type: "", 
              value: Google::Protobuf::Any.pack(val)
            )
          end

          req = SDK::Platform::Capability::NamedRequest.new(
            name: cap_name.to_s,
            func_args: SDK::FuncSpec::Args.new(
              args: arg_protos
            )
          )
          @client.capability(req)
        end
      end
    end
  end
end
