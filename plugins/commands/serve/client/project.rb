module VagrantPlugins
  module CommandServe
    module Client
      class Project

        attr_reader :client
        attr_reader :resource_id

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

        def ref
          SDK::Ref::Project.new(resource_id: resource_id)
        end

        # Returns a machine client for the given name
        # return [VagrantPlugins::CommandServe::Client::Machine]
        def target(name)
          @logger.debug("searching for target #{name}")
          req = SDK::Project::TargetRequest.new(name: name)
          begin
            raw_target = @client.target(req)
          rescue
            @logger.debug("no target found for #{name}")
            raise "Failed to locate requested machine `#{name}'"
          end
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

        # return [VagrantPlugins::CommandServe::Client::MachineIndex]
        def machine_index
          @logger.debug("connecting to machine index")
          req = Google::Protobuf::Empty.new
          begin
            raw_target_index = @client.target_index(req)
          rescue => error
            @logger.debug("target index unreachable")
            @logger.debug(error.message)
          end
          @logger.debug("got response #{raw_target_index}")
          # ti = SDK::Args::TargetIndex.decode(raw_target_index)
          # @logger.debug("decoded: #{ti}")
          @logger.debug("at stream id: #{raw_target_index.stream_id}")
          m = MachineIndex.load(raw_target_index, broker: @broker)
          @logger.debug("got machine index #{m}")
          m
        end
      end
    end
  end
end
