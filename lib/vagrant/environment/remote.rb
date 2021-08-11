require 'vagrant/machine_index/remote'

module Vagrant
  class Environment
    module Remote

      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      def initialize(opts={})
        @client = opts[:client]
        if @client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end
        super
        @logger = Log4r::Logger.new("vagrant::environment")
      end

      # Gets a target (machine) by name
      #
      # @param [String] machine name
      # return [VagrantPlugins::CommandServe::Client::Machine]
      def get_target(name)
        client.target(name)
      end

      # The {MachineIndex} to store information about the machines.
      #
      # @return [MachineIndex]
      def machine_index
        # When starting up in server mode, Vagrant will set the environment
        # client to the value `:stub`. So, check that we have an actual
        # CommandServe::Client::Project by checking for a client
        if @client.class != Symbol
          machine_index_client = @client.machine_index
          @machine_index ||= Vagrant::MachineIndex.new()
          @machine_index.client = machine_index_client
          @machine_index
        end
        @machine_index
      end
    end
  end
end
