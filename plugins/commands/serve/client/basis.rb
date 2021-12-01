module VagrantPlugins
  module CommandServe
    module Client
      class Basis
        prepend Util::ClientSetup
        prepend Util::HasLogger
        prepend Util::HasMapper

        # return [Sdk::Args::DataDir::Basis]
        def data_dirs
          resp = client.data_dir(Empty.new)
          resp
        end

        # return [String]
        def data_dir
          data_dirs.data_dir
        end

        # @return [Terminal]
        def ui
          begin
            Terminal.load(
              client.ui(Google::Protobuf::Empty.new),
              broker: @broker,
            )
          rescue => err
            raise "Failed to load terminal via project: #{err}"
          end
        end

        # @return [Host]
        def host
          h = client.host(Empty.new)
          Host.load(h, broker: broker)
        end

        # @param [List<String>] the type of plugin to get
        # @return [List<Client::*>] a list of plugin clients that match the type requested
        def plugins(types)
          plugins_response = client.plugins(
            SDK::Basis::PluginsRequest.new(types: Array(types))
          )
          plugins = []
          plugins_response.plugins.each do |plg|
            logger.debug("mappng plugin: #{plg}")
            unany_plg = mapper.unany(plg.plugin)
            plugins << mapper.map(unany_plg, broker)
          end
          plugins
        end
      end
    end
  end
end
