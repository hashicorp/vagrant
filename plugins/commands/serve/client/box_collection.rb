# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class BoxCollection < Client
        # @return [Vagrant::Box] box added
        def add(path, name, version, force=false, metadata_url=nil, providers=[])
          logger.debug("adding box at path #{path}")
          args_path = SDK::Args::Path.new(path: path.to_s)
          res = client.add(SDK::BoxCollection::AddRequest.new(
            path: args_path, name: name, version: version, metadataUrl: metadata_url,
            force: force, providers: Array(providers)
          ))
          box_client = Box.load(res, broker: broker)
          box = Vagrant::Box.new(
            box_client.name,
            box_client.provider.to_sym,
            box_client.version,
            Pathname.new(box_client.directory),
            metadata_url: box_client.metadata_url,
            client: box_client
          )
          box
        end

        # @return [List<Vagrant::Box>] all the boxes available
        def all
          res = client.all(Empty.new)
          boxes = []
          res.boxes.each do |box|
            box_client = Box.load(box, broker: broker)
            boxes << Vagrant::Box.new(
              box_client.name,
              box_client.provider.to_sym,
              box_client.version,
              Pathname.new(box_client.directory),
              metadata_url: box_client.metadata_url,
              client: box_client
            )
          end
          boxes
        end

        def clean(name)
          client.clean(
            SDK::BoxCollection::CleanRequest.new(name: name)
          )
        end

        # @return [Vagrant::Box] box found
        def find(name, providers, version)
          begin
            res = client.find(SDK::BoxCollection::FindRequest.new(
              name: name, version: version, providers: Array(providers)
            ))
          rescue GRPC::NotFound
            logger.debug("box not found!")
            return nil
          end
          box_client = Box.load(res, broker: broker)
          box = Vagrant::Box.new(
            box_client.name,
            box_client.provider.to_sym,
            box_client.version,
            Pathname.new(box_client.directory),
            metadata_url: box_client.metadata_url,
            client: box_client
          )
          box
        end
      end
    end
  end
end
