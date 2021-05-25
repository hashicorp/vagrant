module VagrantPlugins
  module CommandServe
    module Client
      class Project

        attr_reader :client

        def initialize(conn)
          @client = SDK::ProjectService::Stub.new(conn, :this_channel_is_insecure)
        end

        def self.load(raw_project)
          m = SDK::Args::Project.decode(raw_project)
          conn = Broker.instance.dial(m.stream_id)
          self.new(conn.to_s)
        end

      end
    end
  end
end
