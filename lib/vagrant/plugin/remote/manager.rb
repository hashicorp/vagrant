require "log4r"

module Vagrant
  module Plugin
    module Remote
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        class << self
          attr_accessor :client
        end

        WRAPPER_CLASS = proc do |klass|
          class << klass
            attr_accessor :plugin_name, :type
            def name
              "Vagrant::Plugin::Remote::#{type.to_s.split(/-_/).map(&:capitalize).join}"
            end

            def to_s
              "<#{name} plugin_name=#{plugin_name}>"
            end

            def inspect
              "<#{name} plugin_name=#{plugin_name} type=#{type}>"
            end

            def inherited(klass)
              klass.plugin_name = plugin_name
              klass.type = type
            end
          end

          def initialize(*args, **kwargs, &block)
            client = Manager.client.get_plugin(
              name: self.class.plugin_name,
              type: self.class.type
            )
            kwargs[:client] = client
            super(*args, **kwargs, &block)
          end

          def name
            self.class.plugin_name
          end

          def inspect
            "<#{self.class.name}:#{object_id} plugin_name=#{name} type=#{self.class.type}>"
          end

          def to_s
            "<#{self.class.name}:#{object_id}>"
          end
        end

        attr_reader :real_manager

        def initialize(manager)
          @logger = Log4r::Logger.new(self.class.name.downcase)
          @real_manager = manager
        end

        def method_missing(m, *args, **kwargs, &block)
          @logger.debug("method not defined, sending to real manager `#{m}'")
          @real_manager.send(m, *args, **kwargs, &block)
        end

        def plugin_manager
          self.class.client
        end

        # Synced folder plugins are registered with an integer priority, but in
        # remote mode this is all captured by InternalService#get_plugins and
        # handled on the Go sidw. Within the remote manager we return a stub
        # value to ensure that any callers get the same shape of return value
        # from the registry and don't blow up.
        SYNCED_FOLDERS_STUB_PRIORITY = 123

        # This returns all synced folder implementations.
        #
        # @return [Registry]
        def synced_folders
          return real_manager.synced_folders if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:synced_folder).each do |plg|
              sf_class = Class.new(V2::SyncedFolder, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                [sf_class, SYNCED_FOLDERS_STUB_PRIORITY]
              end
            end
          end
        end

        def commands
          return real_manager.synced_folders if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:command).each do |plg|
              sf_class = Class.new(V2::Command, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                [proc{sf_class}, {}] # TODO(spox): Options hash should be what?
              end
            end
          end
        end

        # def communicators
        #   return real_manager.synced_folders if plugin_manager.nil?

        #   Registry.new.tap do |result|
        #     plugin_manager.list_plugins(:communicator).each do |plg|
        #       sf_class = Class.new(V2::Communicator, &WRAPPER_CLASS)
        #       sf_class.plugin_name = plg[:name]
        #       sf_class.type = plg[:type]
        #       result.register(plg[:name].to_sym) do
        #         proc{sf_class}
        #       end
        #     end
        #   end
        # end

        # def config
        #   return real_manager.synced_folders if plugin_manager.nil?

        #   Registry.new.tap do |result|
        #     plugin_manager.list_plugins(:config).each do |plg|
        #       sf_class = Class.new(V2::Config, &WRAPPER_CLASS)
        #       sf_class.plugin_name = plg[:name]
        #       sf_class.type = plg[:type]
        #       result.register(plg[:name].to_sym) do
        #         proc{sf_class}
        #       end
        #     end
        #   end
        # end

        def guests
          return real_manager.synced_folders if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:guest).each do |plg|
              sf_class = Class.new(V2::Guest, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                proc{sf_class}
              end
            end
          end
        end

        def hosts
          return real_manager.synced_folders if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:host).each do |plg|
              sf_class = Class.new(V2::Host, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                proc{sf_class}
              end
            end
          end
        end

        def providers
          return real_manager.providers if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:provider).each do |plg|
              sf_class = Class.new(V2::Provider, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                # TODO: Options hash should be what?
                [sf_class, {}]
              end
            end
          end
        end

        # def provisioners
        #   return real_manager.synced_folders if plugin_manager.nil?

        #   Registry.new.tap do |result|
        #     plugin_manager.list_plugins(:provisioner).each do |plg|
        #       sf_class = Class.new(V2::Provisioner, &WRAPPER_CLASS)
        #       sf_class.plugin_name = plg[:name]
        #       sf_class.type = plg[:type]
        #       result.register(plg[:name].to_sym) do
        #         proc{sf_class}
        #       end
        #     end
        #   end
        # end

        def pushes
          return real_manager.pushes if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:push).each do |plg|
              sf_class = Class.new(V2::Push, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                sf_class
              end
            end
          end
        end
      end
    end
  end
end
