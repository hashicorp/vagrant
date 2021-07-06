module VagrantPlugins
  module CommandServe
    module Client
      class Project

        attr_reader :client

        def initialize(conn, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::project")
          @client = SDK::ProjectService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
        end

        def self.load(raw_project, broker:)
          p = SDK::Args::Project.decode(raw_project)
          conn = broker.dial(p.stream_id)
          self.new(conn.to_s, broker)
        end

        # Returns a machine client for the given name
        def target(name)
          @logger.debug("searching for target #{name}")
          req = SDK::Project::TargetRequest.new(name: name)
          raw_target = @client.target(req)
          @logger.debug("got target #{raw_target}")
          conn = @broker.dial(raw_target.stream_id)
          target_service = SDK::TargetService::Stub.new(conn.to_s, :this_channel_is_insecure)
          @logger.debug("specializing target")

          machine = target_service.specialize(Google::Protobuf::Any.new)
          @logger.debug("got machine #{machine}")

          m = SDK::Args::Target::Machine.decode(machine.value)
          conn = @broker.dial(m.stream_id)
          return Machine.new(conn.to_s)
        end
      end
    end
  end
end
