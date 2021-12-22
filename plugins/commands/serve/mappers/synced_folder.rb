module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a synced folder client from a proto instance
      class SyncedFolderProtoFromInstance < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Vagrant::Plugin::V2::SyncedFolder)
          end
          super(inputs: inputs, output: SDK::Args::SyncedFolder, func: method(:converter))
        end

        def converter(plg)
          plg.to_proto
        end
      end

      # Build a synced folder client from a Synced Folder client
      class SyncedFolderProtoFromClient < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::SyncedFolder)
          end
          super(inputs: inputs, output: SDK::Args::SyncedFolder, func: method(:converter))
        end

        def converter(client)
          client.to_proto
        end
      end

      # Build a synced folder client from a proto instance
      class SyncedFolderClientFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: SDK::Args::SyncedFolder)
            i << Input.new(type: Broker)
            i << Input.new(type: Util::Cacher)
          end
          super(inputs: inputs, output: Client::SyncedFolder, func: method(:converter))
        end

        def converter(proto, broker, cacher)
          cid = proto.target.to_s if proto.target.to_s != ""
          return cacher[cid] if cid && cacher.registered?(cid)

          project = Client::SyncedFolder.load(proto, broker: broker)
          cacher[cid] = project if cid
          project
        end
      end

      # Build a synced folder client from a serialized proto string
      class SyncedFolderFromString < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: String)
            i << Input.new(type: Broker)
          end
          super(inputs: inputs, output: Client::SyncedFolder, func: method(:converter))
        end

        def converter(proto, broker)
          Client::SyncedFolder.load(proto, broker: broker)
        end
      end

      # Build a synced folder from a synced folder client
      class SyncedFolderFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::SyncedFolder)
          end
          super(inputs: inputs, output: Vagrant::Plugin::V2::SyncedFolder, func: method(:converter))
        end

        def converter(client)
          Vagrant::Plugin::V2::SyncedFolder.new(client)
        end
      end
    end
  end
end
