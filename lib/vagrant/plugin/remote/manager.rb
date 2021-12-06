require "log4r"

module Vagrant
  module Plugin
    module Remote
      # This class maintains a list of all the registered plugins as well
      # as provides methods that allow querying all registered components of
      # those plugins as a single unit.
      class Manager < Vagrant::Plugin::V2::Manager
        attr_reader :registered

        def initialize
          @logger = Log4r::Logger.new("vagrant::plugin::remote::manager")
          @logger.debug("initializing remote manager")
          # Copy in local Ruby registered plugins
          @registered = Vagrant.plugin("2").manager.registered
        end

        # This returns all synced folder implementations.
        #
        # @return [Registry]
        def synced_folders
          Registry.new.tap do |result|
            @registered.each do |plugin|
              plugin.components.synced_folders.each do |k, v|
                sf_class = Class.new(v[0])
                sf_class.class_eval do
                  def initialize(*_, **_)
                    super(@@client)
                  end
                  def self.client=(val)
                    @@client=val
                  end
                  def self.client
                    @@client
                  end
                end
                # TODO: set the actual client
                sf_class.client = "todo"
                v = [sf_class] + v[1..]
                result.register(k) do
                  v
                end
              end
            end
          end
        end

        # Registers remote plugins provided from the client
        #
        # @param [VagrantPlugin::Command::Serve::Client::Basis]
        def register_remote_plugins(client)
          # TODO
        end
      end
    end
  end
end
