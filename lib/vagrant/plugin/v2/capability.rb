# coding: utf-8
module Vagrant
  module Plugin
    module V2
      # Base class responsible for defining a capability in Vagrant.
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
          define_method(name, &block) if block_given?
        end
        
        def detect?
          false
        end
      end
    end
  end
end

