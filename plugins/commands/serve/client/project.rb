module VagrantPlugins
  module CommandServe
    module Client
      class Project
        prepend Util::ClientSetup
        prepend Util::HasLogger

        # return [VagrantPlugins::CommandServe::Client::BoxCollection]
        def boxes
          BoxCollection.load(
            client.boxes(Empty.new),
            broker: broker
          )
        end

        # return [String]
        def cache_dir
          data_dirs.cache_dir
        end

        # return [String]
        def config_dir
          data_dirs.config_dir
        end

        # return [String]
        def cwd
          resp = client.cwd(Empty.new)
          resp.path
        end

        # return [Sdk::Args::DataDir::Project]
        def data_dirs
          resp = client.data_dir(Empty.new)
          resp
        end

        # return [String]
        def data_dir
          data_dirs.data_dir
        end

        # return [String]
        def default_private_key
          resp = client.default_private_key(Empty.new)
          resp.key
        end

        # return [String]
        def local_data
          resp = client.local_data(Empty.new)
          resp.path
        end

        # return [String]
        def home
          resp = client.home(Empty.new)
          resp.path
        end

        # TODO
        def host
          h = client.host(Empty.new)
          Host.load(h, broker: broker)
        end

        # return [<String>]
        def target_names
          resp = client.target_names(Empty.new)
          resp.names
        end

        # return [VagrantPlugins::CommandServe::Client::TargetIndex]
        def target_index
          TargetIndex.load(
            client.target_index(Empty.new),
            broker: broker
          )
        end

        # return [<String>]
        def target_ids
          resp = client.target_ids(Empty.new)
          resp.ids
        end

        # Returns a machine client for the given name
        # return [VagrantPlugins::CommandServe::Client::Target::Machine]
        def target(name)
          logger.debug("searching for target #{name}")
          target = Target.load(
            client.target(SDK::Project::TargetRequest.new(name: name)),
            broker: broker
          )
          target.to_machine
        end

        # return [String]
        def temp_dir
          data_dirs.temp_dir
        end

        # return [String]
        def tmp
          resp = client.tmp(Empty.new)
          resp.path
        end

        # @return [String] name of the Vagrantfile for this target
        def vagrantfile_name
          client.vagrantfile_name(Empty.new).name
        end

        # @return [Pathname] path to the Vagrnatfile for this target
        def vagrantfile_path
          Pathname.new(client.vagrantfile_path(Empty.new).path)
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
      end
    end
  end
end
