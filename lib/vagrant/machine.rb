require "log4r"

module Vagrant
  # This represents a machine that Vagrant manages. This provides a singular
  # API for querying the state and making state changes to the machine, which
  # is backed by any sort of provider (VirtualBox, VMWare, etc.).
  class Machine
    # The box that is backing this machine.
    #
    # @return [Box]
    attr_reader :box

    # Configuration for the machine.
    #
    # @return [Object]
    attr_reader :config

    # The environment that this machine is a part of.
    #
    # @return [Environment]
    attr_reader :env

    # Name of the machine. This is assigned by the Vagrantfile.
    #
    # @return [String]
    attr_reader :name

    # Initialize a new machine.
    #
    # @param [String] name Name of the virtual machine.
    # @param [Object] provider The provider backing this machine. This is
    #   currently expected to be a V1 `provider` plugin.
    # @param [Object] config The configuration for this machine.
    # @param [Box] box The box that is backing this virtual machine.
    # @param [Environment] env The environment that this machine is a
    #   part of.
    def initialize(name, provider, config, box, env)
      @name   = name
      @config = config
      @box    = box
      @env    = env
    end
  end
end
