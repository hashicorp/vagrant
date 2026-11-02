# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Mappers
      # Build a synced folder client from a proto instance
      class SyncedFolderProtoFromInstance < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Vagrant::Plugin::Remote::SyncedFolder)
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
          cid = proto.addr.to_s if proto.addr.to_s != ""
          return cacher.get(cid) if cid && cacher.registered?(cid)

          sf = Client::SyncedFolder.load(proto, broker: broker)
          cacher.register(cid, sf) if cid
          sf
        end
      end

      # Build a synced folder from a synced folder client
      class SyncedFolderFromProto < Mapper
        def initialize
          inputs = [].tap do |i|
            i << Input.new(type: Client::SyncedFolder)
          end
          super(inputs: inputs, output: Vagrant::Plugin::Remote::SyncedFolder, func: method(:converter))
        end

        def converter(client)
          Vagrant::Plugin::Remote::SyncedFolder.new(client: client)
        end
      end
    end
  end
end
