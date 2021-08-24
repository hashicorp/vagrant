module VagrantPlugins
  module CommandServe
    module Client
      class Project
        extend Util::Connector

        attr_reader :broker
        attr_reader :client
        attr_reader :proto

        def initialize(conn, proto, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::project")
          @logger.debug("connecting to project service on #{conn}")
          @client = SDK::ProjectService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
          @proto = proto
        end

        def self.load(raw_project, broker:)
          p = raw_project.is_a?(String) ? SDK::Args::Project.decode(raw_project) : raw_project
          self.new(connect(proto: p, broker: broker), p, broker)
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
          resp = @client.cwd(Google::Protobuf::Empty.new)
          resp.path
        end

        # return [Sdk::Args::DataDir::Project]
        def data_dirs
          resp = @client.data_dir(Google::Protobuf::Empty.new)
          resp
        end

        # return [String]
        def data_dir 
          data_dirs.data_dir
        end

        # return [String]
        def default_private_key
          resp = @client.default_private_key(Google::Protobuf::Empty.new)
          resp.key
        end

        # return [String]
        def local_data
          resp = @client.local_data(Google::Protobuf::Empty.new)
          resp.path
        end

        # return [String]
        def home
          resp = @client.home(Google::Protobuf::Empty.new)
          resp.path
        end

        # TODO
        def host
          @client.host(Google::Protobuf::Empty.new)
          # TODO load the remote host plugin.
          nil
        end

        # return [<String>]
        def target_names
          resp = @client.target_names(Google::Protobuf::Empty.new)
          resp.names
        end

        # return [VagrantPlugins::CommandServe::Client::TargetIndex]
        def target_index
          TargetIndex.load(
            @client.target_index(Empty.new),
            broker: broker
          )
        end

        # return [<String>]
        def target_ids
          resp = @client.target_ids(Google::Protobuf::Empty.new)
          resp.ids
        end

        # Returns a machine client for the given name
        # return [VagrantPlugins::CommandServe::Client::Machine]
        def target(name)
          @logger.debug("searching for target #{name}")
          target = Target.load(
            client.target(SDK::Project::TargetRequest.new(name: name)),
            broker: @broker
          )
          target.to_machine
        end

        # return [String]
        def temp_dir
          data_dirs.temp_dir
        end

        # return [String]
        def tmp
          resp = @client.tmp(Google::Protobuf::Empty.new)
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
      end
    end
  end
end
