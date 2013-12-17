# coding: utf-8
module Vagrant
  module Plugin
    module V2
      # Base class responsible for defining a capability in Vagrant.  A 
      # capability is responsible for exposing specialized, unique features
      # of a particular subsystem of a machine.
      class Capability
        # This should return a brief (60 characters or less) synposis of what
        # this capability does.  It will be used in the output of the help.
        # 
        # @return [String]
        def self.synopsis
          ''
        end

        # The name of the capability.
        #
        # @return [Symbol] 
        attr_reader :name

        # Initializes the capability with the machine (and guest, provider)
        # that we will enumerate. If a block is given it will be defined as
        # a method on a new instance of this object with the given name.
        #
        # @param [Symbol] name Capability identifier name.
        def initialize(name, &block)
          @name = name.to_sym
          
          # When a block is passed into the initialization of this class we
          # treat it as an callable which responds when called with the name
          # of the capability. This is mainly for backwards compatability. 
          if block_given?
            alias_method(name, execute)
            define_method('execute', -> { k = block.call; k.send(@name) })
          end
        end

        # Executes the capability in the context of the machine and name provided.
        # 
        # @param [Vagrant::Machine] machine
        # @param [String] name The name of the capability.
        def execute(machine, name)
        end

        def detect?(machine)
          false
        end
      end
    end
  end
end

