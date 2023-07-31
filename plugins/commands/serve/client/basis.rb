# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Basis < Client
        def boxes
          BoxCollection.load(
            client.boxes(Empty.new),
            broker: broker
          )
        end

        def cwd
          resp = client.cwd(Empty.new)
          resp.path
        end

        # return [Sdk::Args::DataDir::Basis]
        def data_dirs
          resp = client.data_dir(Empty.new)
          resp
        end

        # return [String]
        def data_dir
          data_dirs.data_dir
        end

        def default_private_key
          resp = client.default_private_key(Empty.new)
          resp.path
        end

        def default_provider(**opts)
          resp = client.default_provider(Empty.new)
          resp.provider_name.to_sym
        end

        def target_index
          TargetIndex.load(
            client.target_index(Empty.new),
            broker: broker
          )
        end

        def vagrantfile
          client.vagrantfile(Empty.new).to_ruby
        end

        # @return [Terminal]
        def ui
          begin
            Terminal.load(
              client.ui(Google::Protobuf::Empty.new),
              broker: @broker,
            )
          rescue => err
            raise "Failed to load terminal via basis: #{err}"
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
          plugins = {}
          plugins_response.plugins.each do |plg|
            logger.debug("mappng plugin: #{plg}")
            unany_plg = mapper.unany(plg.plugin)
            plugins[plg.name.to_sym] = mapper.map(unany_plg, broker)
          end
          plugins
        end

        def local_data
          data_dirs.data_dir
        end

        def temp_dir
          data_dirs.temp_dir
        end
      end
    end
  end
end
