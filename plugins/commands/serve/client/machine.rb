module VagrantPlugins
  module CommandServe
    module Client
      class Machine

        attr_reader :client
        attr_reader :resource_id

        def initialize(conn)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::machine")
          @logger.debug("connecting to target machine service on #{conn}")
          @client = SDK::TargetMachineService::Stub.new(conn, :this_channel_is_insecure)
        end

        def self.load(raw_machine, broker:)
          m = SDK::Args::Target.decode(raw_machine)
          conn = broker.dial(m.stream_id)
          self.new(conn.to_s)
        end

        def ref
          SDK::Ref::Machine.new(resource_id: resource_id)
        end

        # @return [String] machine name
        def get_name
          req = Google::Protobuf::Empty.new
          @client.name(req).name
        end

        def set_name(name)
          req = SDK::Target::SetNameRequest.new(
            name: name
          )
          @client.set_name(req)
        end

        def get_id
          req = Google::Protobuf::Empty.new
          result = @client.get_id(req).id
          @logger.debug("Got remote machine id: #{result}")
          if result.nil?
            raise "Failed to get machine ID. REF: #{ref.inspect} - ID WAS NIL"
          end
          result
        end

        def set_id(new_id)
          req = SDK::Target::Machine::SetIDRequest.new(
            id: new_id
          )
          @client.set_id(req)
        end

        def get_box
          req = Google::Protobuf::Empty.new
          resp = @client.box(req)
          Vagrant::Box.new(
            resp.box.name,
            resp.box.provider.to_sym,
            resp.box.version,
            Pathname.new(resp.box.directory),
          )
        end

        def get_data_dir
          req = Google::Protobuf::Empty.new
          @client.datadir(req).data_dir
        end

        # TODO: local data path comes from the project
        def get_local_data_path
          req = SDK::Machine::LocalDataPathRequest.new(
            machine: ref
          )
          @client.localdatapath(req).path
        end

        def get_provider
          req = Google::Protobuf::Empty.new
          @client.provider(req)
        end

        def get_vagrantfile_name
          req = Google::Protobuf::Empty.new
          resp = @client.vagrantfile_name(req)
          resp.name
        end

        def get_vagrantfile_path
          req = Google::Protobuf::Empty.new
          resp = @client.vagrantfile_path(req)
          Pathname.new(resp.path)
        end

        def updated_at
          req = Google::Protobuf::Empty.new
          resp = @client.updated_at(req)
          resp.updated_at
        end

        def get_state
          # req = Google::Protobuf::Empty.new
          # resp = @client.get_state(req)
          # @logger.debug("Got state #{resp}")
          # Vagrant::MachineState.new(
          #   resp.state.id.to_sym,
          #   resp.state.short_description,
          #   resp.state.long_description
          # )
          Vagrant::MachineState.new(
            :UNKNOWN,
            "all good",
            "you know, all good"
          )
        end

        alias state get_state

        # @param [SRV::Operation::PhysicalState] state of the machine
        def set_state(state)
          req = SDK::Target::Machine::SetStateRequest.new(
            state: SDK::Args::Target::Machine::State.new(
              id: state.id,
              short_description: state.short_description,
              long_description: state.long_description,
            )
          )
          @client.set_state(req)
        end

        def get_uuid
          req = Google::Protobuf::Empty.new
          @client.get_uuid(req).uuid
        end
      end
    end
  end
end
