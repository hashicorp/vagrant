module Vagrant
  class Machine
    class Thin < Machine

      attr_reader :env
      attr_reader :ui

      attr_reader :client
      # NOTE: The client is internal so don't make it publicly accessible
      protected :client

      def initialize(name, provider_name, provider_cls, provider_config, provider_options, config, data_dir, box, env, vagrantfile, base=false)
        @env = env
        @ui = Vagrant::UI::Prefixed.new(@env.ui, name)
        @client = VagrantPlugins::CommandServe::Client::Machine.new(name: name)
        @provider_name = provider_name
        @provider = provider_cls.new(self)
        @provider._initialize(provider_name, self)
      end

      # @return [Box]
      def box
        client.get_box
      end

      def config
        raise NotImplementedError, "TODO"
      end

      # @return [Pathname]
      def data_dir
        Pathname.new(client.get_data_dir)
      end

      def id
        client.get_id
      end

      def name
        client.get_name
      end

      def index_uuid
        client.get_uuid
      end

      def recover_machine(*_)
        nil
      end

      def state
        client.get_state
      end

      ####
      def provider
        @provider
      end

      def provider_name
        @provider_name
      end
      ###

      def inspect
        "<Vagrant::Machine:resource_id=#{client.resource_id}>"
      end
    end
  end
end
