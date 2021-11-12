module VagrantPlugins
  module CommandServe
    module Client
      class BoxCollection
        prepend Util::ClientSetup
        prepend Util::HasLogger

        # @return [Vagrant::Box] box added
        def add(path, name, version, force=false, metadata_url=nil, providers=[])
          res = client.add(SDK::BoxCollection::AddRequest.new(
            path: path, name: name, version: version, metadataUrl: metadata_url, 
            force: force, providers: providers
          ))
          box_client = Box.load(res, broker: broker)
          box = Vagrant::Box.new(
            box_client.name,
            box_client.provider.to_sym,
            box_client.version,
            Pathname.new(box_client.directory),
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
        def find(name, providers, versions)
          res = client.find(SDK::BoxCollection::FindRequest.new(
            name: name, version: version, providers: providers
          ))
          box_client = Box.load(res, broker: broker)
          box = Vagrant::Box.new(
            box_client.name,
            box_client.provider.to_sym,
            box_client.version,
            Pathname.new(box_client.directory),
            client: box_client
          )
          box
        end
      end
    end
  end
end
