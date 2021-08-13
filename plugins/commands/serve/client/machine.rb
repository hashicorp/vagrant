module VagrantPlugins
  module CommandServe
    module Client
      # Machine is a specialization of a generic Target
      # and is how legacy Vagrant willl interact with
      # targets
      class Machine < Target

        extend Util::Connector

        def initialize(conn, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::machine")
          @logger.debug("connecting to target machine service on #{conn}")
          @client = SDK::TargetMachineService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
        end

        def self.load(raw_machine, broker:)
          m = SDK::Args::Target::Machine.decode(raw_machine)
          self.new(connect(proto: m, broker: broker), broker)
        end

        # @return [String] resource identifier for this target
        def ref
          SDK::Ref::Target::Machine.new(resource_id: resource_id)
        end

        # @return [String] machine identifier
        def get_id
          client.get_id(Empty.new).id
        end

        # Set ID for machine
        #
        # @param [String] new_id New machine ID
        def set_id(new_id)
          client.set_id(
            SDK::Target::Machine::SetIDRequest.new(
              id: new_id
            )
          )
        end

        # @return [Vagrant::Box] box backing machine
        def box
          resp = client.box(Empty.new)
          Vagrant::Box.new(
            resp.box.name,
            resp.box.provider.to_sym,
            resp.box.version,
            Pathname.new(resp.box.directory),
          )
        end

        def get_dir
          req = Google::Protobuf::Empty.new
          @client.data_dir(req)
        end

        def get_data_dir
          dir = get_dir
          Pathname.new(dir.data_dir)
        end

        # @return [Vagrant::MachineState] current state of machine
        def get_state
          resp = client.get_state(Empty.new)
          Vagrant::MachineState.new(
            resp.id.to_sym,
            resp.short_description,
            resp.long_description
          )
        end

        # Set the current state of the machine
        #
        # @param [Vagrant::MachineState] state of the machine
        def set_state(state)
          req = SDK::Target::Machine::SetStateRequest.new(
            state: SDK::Args::Target::Machine::State.new(
              id: state.id,
              short_description: state.short_description,
              long_description: state.long_description,
            )
          )
          client.set_state(req)
        end

        # @return [Guest] machine guest
        # TODO: This needs to be loaded properly
        def guest
          client.guest(Empty.new)
        end

        # Force a reload of the machine state
        def reload
          client.reload(Empty.new)
        end

        # @return
        # TODO: This needs some design adjustments
        def connection_info
        end

        # @return [Integer] user ID that owns machine
        def uid
          client.uid(Empty.new).uid
        end

        # TODO: this is setup to return plugins. verify
        def synced_folders
        end
      end
    end
  end
end
