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
        super
        @client = opts[:client]
        if @client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end
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
        if !@client.nil?
          machine_index_client = @client.machine_index
          @machine_index ||= Vagrant::MachineIndex.new()
          @logger.debug("setting machine index client")
          @machine_index.client = machine_index_client
          @logger.debug("setting machine index project ref")
          @machine_index.project_ref = @client.ref
        end
        @machine_index
      end
    end
  end
end
