# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "time"

module VagrantPlugins
  module CommandServe
    class Client
      class Target < Client
        autoload :Machine, Vagrant.source_root.join("plugins/commands/serve/client/target/machine").to_s

        STATES = [
          :UNKNOWN,
          :PENDING,
          :CREATED,
          :DESTROYED,
        ].freeze


        # @return [SDK::Ref::Target] proto reference for this target
        def vagrantfile
          client.vagrantfile(Empty.new).to_ruby
        end

        # @return [SDK::Ref::Target] proto reference for this target
        def ref
          SDK::Ref::Target.new(resource_id: resource_id)
        end

        # @return [Client::Communicator]
        def communicate
          comm_raw = client.communicate(Empty.new)
          Communicator.load(comm_raw, broker: @broker)
        end

        # @return [Pathname] target specific data directory
        def data_dir
          Pathname.new(client.data_dir(Empty.new).data_dir)
        end

        # @return [Boolean] destroy the traget
        def destroy
          client.destroy(Empty.new)
          true
        end

        # @return [Vagrant::Environment]
        def environment
          mapper.map(project, to: Vagrant::Environment)
        end

        # @return [String] Unique identifier of machine
        def get_uuid
          client.get_uuid(Empty.new).uuid
        end

        # @return [Hash] freeform key/value data for target
        def metadata
          kv = client.metadata(Empty.new).metadata
          Vagrant::Util::HashWithIndifferentAccess.new(kv.to_h)
        end

        # @return [String] name of target
        def name
          client.name(Empty.new).name
        end

        # @return [Project] project this target is within
        def project
          Project.load(client.project(Empty.new), broker: broker)
        end

        def environment
          client.project(Empty.new).to_ruby
        end

        # @return [Provider] provider for target
        def provider
          client.provider(Empty.new)
        end

        # @return [String] name of provider for target
        def provider_name
          client.provider_name(Empty.new).name
        end

        # @return [String] resource identifier for this target
        def resource_id
          client.resource_id(Empty.new).resource_id
        end

        # Save the state of the target
        def save
          client.save(Empty.new)
        end

        # Set name of target
        #
        # @param [String] name Name of target
        def set_name(name)
          client.set_name(
            SDK::Target::SetNameRequest.new(
              name: name
            )
          )
        end

        # Set the unique identifier fo the machine
        #
        # @param [String] uuid Uniqe identifier
        def set_uuid(uuid)
          client.set_uuid(
            SDK::Target::Machine::SetUUIDRequest.new(
              uuid: uuid
            )
          )
        end

        # @return [Symbol] state of the target
        def state
          client.state(Empty.new).state
        end

        # @return [Terminal]
        def ui
          t = Terminal.load(
            client.ui(Google::Protobuf::Empty.new),
            broker: @broker,
          )
          mapper.map(t, to: Vagrant::UI::Remote)
        end

        # @return [Time] time target was last updated
        def updated_at
          Time.parse(client.updated_at(Empty.new).updated_at)
        end

        # @return [Machine] specialize target into a machine client
        def to_machine
          Machine.load(
            client.specialize(Google::Protobuf::Any.new).value,
            broker: broker
          )
        end
      end
    end
  end
end
