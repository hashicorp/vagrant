module VagrantPlugins
  module CommandServe
    module Client
      class Project
        extend Util::Connector

        attr_reader :broker
        attr_reader :client

        def initialize(conn, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::project")
          @logger.debug("connecting to project service on #{conn}")
          @client = SDK::ProjectService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
        end

        def self.load(raw_project, broker:)
          p = raw_project.is_a?(String) ? SDK::Args::Project.decode(raw_project) : raw_project
          self.new(connect(proto: p, broker: broker), broker)
        end

        # Gets the local data path
        # return [String]
        def get_local_data_path
          req = Google::Protobuf::Empty.new
          resp = @client.local_data(req)
          return resp.path
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

        # return [VagrantPlugins::CommandServe::Client::TargetIndex]
        def target_index
          @logger.debug("connecting to target index")
          TargetIndex.load(
            client.target_index(Empty.new),
            broker: broker
          )
        end

        # TODO: fix
        def local_data_path
          Pathname.new('.')
        end

        # @return [String] name of the Vagrantfile for this target
        def vagrantfile_name
          client.vagrantfile_name(Empty.new)
        end

        # @return [Pathname] path to the Vagrnatfile for this target
        def vagrantfile_path
          Pathname.new(client.vagrantfile_path(Empty.new).path)
        end
      end
    end
  end
end
