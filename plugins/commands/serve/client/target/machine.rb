module VagrantPlugins
  module CommandServe
    module Client
      # Machine is a specialization of a generic Target
      # and is how legacy Vagrant willl interact with
      # targets
      class Target
        class Machine < Target

          prepend Util::ClientSetup
          prepend Util::HasLogger

          # @return [String] resource identifier for this target
          def ref
            SDK::Ref::Target::Machine.new(resource_id: resource_id)
          end

          # @return [Vagrant::Box] box backing machine
          def box
            b = client.box(Empty.new)
            box_client = Box.load(b, broker: broker)
            box = Vagrant::Box.new(
              box_client.name,
              box_client.provider.to_sym,
              box_client.version,
              Pathname.new(box_client.directory),
              client: box_client
            )
            box
          end

          # @return
          # TODO: This needs some design adjustments
          def connection_info
          end

          # @return [Communicator] machine communicator
          def communicate
            logger.debug("Getting guest from remote machine")
            c = client.communicate(Empty.new)
            Communicator.load(c, broker: broker)
          end

          # @return [Guest] machine guest
          # TODO: This needs to be loaded properly
          def guest
            logger.debug("Getting guest from remote machine")
            g = client.guest(Empty.new)
            Guest.load(g, broker: broker)
          end

          # @return [String] machine identifier
          def id
            client.get_id(Empty.new).id
          end

          # @return [Vagrant::MachineState] current state of machine
          def machine_state
            resp = client.get_state(Empty.new)
            Vagrant::MachineState.new(
              resp.id.to_sym,
              resp.short_description,
              resp.long_description
            )
          end

          # Force a reload of the machine state
          def reload
            client.reload(Empty.new)
          end

          # Set ID for machine
          #
          # @param [String] new_id New machine ID
          def set_id(new_id)
            if new_id.nil?
              new_id = ""
            end
            client.set_id(
              SDK::Target::Machine::SetIDRequest.new(
                id: new_id
              )
            )
          end

          # Set the current state of the machine
          #
          # @param [Vagrant::MachineState] state of the machine
          def set_machine_state(state)
            req = SDK::Target::Machine::SetStateRequest.new(
              state: SDK::Args::Target::Machine::State.new(
                id: state.id,
                short_description: state.short_description,
                long_description: state.long_description,
              )
            )
            client.set_state(req)
          end

          # Synced folder for machine 
          #
          # @return [List<[Client::SyncedFolder, Map<String, String>]>]
          def synced_folders
            folder_protos = client.synced_folders(Empty.new).synced_folders
            folder_protos.map do |fp|
              {
                plugin: SyncedFolder.load(fp.plugin, broker: broker),
                folder: fp.folder.to_h,
              }
            end
          end

          # @return [Integer] user ID that owns machine
          def uid
            client.uid(Empty.new).uid
          end
        end
      end
    end
  end
end
