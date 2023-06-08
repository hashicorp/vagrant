module VagrantPlugins
  module CommandServe
    class Client
      # Machine is a specialization of a generic Target
      # and is how legacy Vagrant willl interact with
      # targets
      class Target
        class Machine < Target
          # @return [String] resource identifier for this target
          def ref
            SDK::Ref::Machine.new(resource_id: resource_id)
          end

          # @return [Vagrant::Box] box backing machine
          def box
            begin
              b = client.box(Empty.new)
              if b == nil || b.box == nil
                return nil
              end
              box_client = Box.load(b.box, broker: broker)
              box = Vagrant::Box.new(
                box_client.name,
                box_client.provider.to_sym,
                box_client.version,
                Pathname.new(box_client.directory),
                client: box_client
              )
              box
            rescue GRPC::NotFound
              nil
            end
          end

          # @return
          # TODO: This needs some design adjustments
          def connection_info
          end

          # @return [Communicator] machine communicator
          def communicate
            c = client.communicate(Empty.new)
            Communicator.load(c, broker: broker)
          end

          # @return [Guest] machine guest
          def guest
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

          # Return [Provider] provider for the machine
          def provider
            p = client.provider(Empty.new)
            Provider.load(p, broker: broker)
          end

          # Return [Provider] provider for the machine
          def provider_name
            p = client.provider_name(Empty.new)
            p.name
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

          # Convert machine to a generic target
          def to_target
            Target.load(
              client.as_target(Empty.new),
              broker: broker,
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
                folder: _cleaned_folder_hash(fp.folder),
              }
            end
          end

          # @return [Integer] user ID that owns machine
          def uid
            user_id = client.uid(Empty.new).user_id
            return nil if user_id == ""
            return user_id
          end

          def _cleaned_folder_hash(folder)
            folder_hash = folder.options.to_ruby.transform_keys(&:to_sym)
            folder_hash[:source] = folder.source
            folder_hash[:destination] = folder.destination
            folder_hash
          end
        end
      end
    end
  end
end
