# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "log4r"

module Vagrant
  module Plugin
    module Remote
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager
        class << self
          # @return [VagrantPlugins::Command::Serve::Client::PluginManager] remote manager client
          attr_accessor :client

          # @return [VagrantPlugins::Command::Serve::Client::CorePluginManager] remote manager client for core plugins
          attr_accessor :core_client
        end

        # This wrapper class is used for encapsulating a remote plugin class. This
        # block is the content for the anonymous subclass created for the remote
        # plugin. Its job is to store the name and type of a plugin within the
        # class context. When initialized it will use the remote plugin manager
        # to load the proper client into the remote plugin instance. It also
        # handles passing non-API method calls to the local instance of a plugin
        # if the plugin exists within the Ruby runtime.
        WRAPPER_CLASS = proc do |klass|
          class << klass
            # @return [String] name of the plugin (virtualbox, smb, shell, etc.)
            attr_accessor :plugin_name
            # @return [String] type of plugin (Provider, Provisioner, etc.)
            attr_accessor :type

            # @return [String]
            def name
              "Vagrant::Plugin::Remote::#{type.to_s.split(/-_/).map(&:capitalize).join}"
            end

            # @return [String]
            def to_s
              "<#{name} plugin_name=#{plugin_name}>"
            end

            # @return [String]
            def inspect
              "<#{name} plugin_name=#{plugin_name} type=#{type}>"
            end

            def inherited(klass) # :nodoc:

              klass.plugin_name = plugin_name
              klass.type = type
            end

            # @return [VagrantPlugins::Commands::Serve::Client] client for plugin
            def client
              return @client if @client
              @client = Manager.client.get_plugin(
                name: plugin_name,
                type: type
              )
            end
          end

          def initialize(*args, **kwargs, &block)
            @logger = Log4r::Logger.new(self.class.name.downcase)
            kwargs[:client] = self.class.client
            super(*args, **kwargs, &block)
            kwargs.delete(:client)
            @init = [args, kwargs, block]
          end

          # @return [String] name of plugin
          def name
            self.class.plugin_name
          end

          # @return [String]
          def inspect
            "<#{self.class.name}:#{object_id} plugin_name=#{name} type=#{self.class.type}>"
          end

          # @return [String]
          def to_s
            "<#{self.class.name}:#{object_id}>"
          end

          # If an unknown method is called on the plugin, this will check if the
          # actual plugin is local to the Ruby runtime. If it is not, a NoMethodError
          # will be generated. If it is, the local plugin will either be loaded
          # from the cache or instantiated and the method call will be executed
          # against the local plugin instance.
          def method_missing(*args, **kwargs, &block)
            klass = get_local_plugin
            return super if klass.nil?
            @logger.debug("found local plugin class #{self.class.name} -> #{klass.name}")
            c = VagrantPlugins::CommandServe.cache
            key = c.key(klass, *@init[0])
            if !c.registered?(key)
              @logger.debug("creating new local plugin instance of #{klass} with args: #{@init}")
              c.register(key, klass.new(*@init[0], **@init[1], &@init[2]))
            end
            @logger.debug("sending ##{args.first} result to local plugin #{klass}")
            c.get(key).send(*args, **kwargs, &block)
          end

          private

          # @return [Class, NilClass] class of the local plugin
          def get_local_plugin
            m = ["#{self.class.type.downcase}s",
              "#{self.class.type.downcase}es"].detect { |i|
              Vagrant.plugin("2").local_manager.respond_to?(i)
            }
            if m.nil?
              @logger.debug("failed to locate valid local plugin registry method for plugin type #{self.class.type}")
              return
            end
            klass = Array(Vagrant.plugin("2").local_manager.
              send(m)[self.class.plugin_name.to_sym]).first
            @logger.trace("local plugin lookup for #{self.class.name} / #{self.class.plugin_name} / #{self.class.type}: #{klass}")
            klass
          end
        end

        # @return [V2::Manager]
        attr_reader :real_manager

        # Create a new remote plugin manager
        #
        # @param manager [V2::Manger]
        # @return [Remote::Manager]
        def initialize(manager)
          @logger = Log4r::Logger.new(self.class.name.downcase)
          @real_manager = manager
        end

        def method_missing(m, *args, **kwargs, &block)
          @logger.debug("method not defined, sending to real manager `#{m}'")
          @real_manager.send(m, *args, **kwargs, &block)
        end

        # @return [VagrantPlugins::Command::Serve::Client::PluginManager] remote manager client
        def plugin_manager
          self.class.client
        end

        # @return [VagrantPlugins::Command::Serve::Client::CorePluginManager] remote core manager client
        def core_plugin_manager
          self.class.core_client
        end

        # This returns all synced folder implementations.
        #
        # @return [Registry]
        def synced_folders
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:synced_folder).each do |plg|
              sf_class = Class.new(Remote::SyncedFolder, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                # The integer priority has already been captured on the Go side
                # by InternalService#get_plugins. It's returned in the plugin
                # options field, and we populate it into the same place for
                # good measure, even though we expect that priority will be
                # handled on the Go side now.
                [sf_class, plg[:options]]
              end
            end
          end
        end

        # This returns all command implementations.
        #
        # @return [Registry]
        def commands
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:command).each do |plg|
              sf_class = Class.new(Remote::Command, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                [proc{sf_class}, plg[:options]]
              end
            end
          end
        end

        # This returns all communicator implementations.
        #
        # @return [Registry]
        def communicators
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:communicator).each do |plg|
              sf_class = Class.new(Remote::Communicator, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                proc{sf_class}
              end
            end
          end
        end

        # def config
        #   return real_manager.synced_folders if plugin_manager.nil?

        #   Registry.new.tap do |result|
        #     plugin_manager.list_plugins(:config).each do |plg|
        #       sf_class = Class.new(Remote::Config, &WRAPPER_CLASS)
        #       sf_class.plugin_name = plg[:name]
        #       sf_class.type = plg[:type]
        #       result.register(plg[:name].to_sym) do
        #         proc{sf_class}
        #       end
        #     end
        #   end
        # end

        # This returns all guest implementations.
        #
        # @return [Registry]
        def guests
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:guest).each do |plg|
              sf_class = Class.new(Remote::Guest, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                proc{sf_class}
              end
            end
          end
        end

        # This returns all host implementations.
        #
        # @return [Registry]
        def hosts
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:host).each do |plg|
              sf_class = Class.new(Remote::Host, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                proc{sf_class}
              end
            end
          end
        end

        # This returns all provider implementations.
        #
        # @return [Registry]
        def providers
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:provider).each do |plg|
              sf_class = Class.new(Remote::Provider, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                [sf_class, plg[:options]]
              end
            end
          end
        end

        def provisioners
          return real_manager.provisioners if plugin_manager.nil?

          Registry.new.tap do |result|
            plugin_manager.list_plugins(:provisioner).each do |plg|
              sf_class = Class.new(Remote::Provisioner, &WRAPPER_CLASS)
              sf_class.plugin_name = plg[:name]
              sf_class.type = plg[:type]
              result.register(plg[:name].to_sym) do
                sf_class
              end
            end
          end
        end

        # This returns all push implementations.
        #
        # @return [Registry]
        def pushes
          Registry.new.tap do |result|
            plugin_manager.list_plugins(:push).each do |plg|
              sf_class = Class.new(Remote::Push, &WRAPPER_CLASS)
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
