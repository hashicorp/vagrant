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
            resp = client.box(Empty.new)
            Vagrant::Box.new(
              resp.box.name,
              resp.box.provider.to_sym,
              resp.box.version,
              Pathname.new(resp.box.directory),
            )
          end

          # @return
          # TODO: This needs some design adjustments
          def connection_info
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

          # TODO: this is setup to return plugins. verify
          def synced_folders
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
