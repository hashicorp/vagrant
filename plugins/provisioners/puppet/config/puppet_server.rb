module VagrantPlugins
  module Puppet
    module Config
      class PuppetServer < Vagrant.plugin("2", :config)
        attr_accessor :puppet_server
        attr_accessor :puppet_node
        attr_accessor :options
        attr_accessor :facter

        def initialize
          super

          @facter        = {}
          @options       = []
          @puppet_node   = UNSET_VALUE
          @puppet_server = UNSET_VALUE
        end

        def finalize!
          super

          @puppet_node   = nil if @puppet_node == UNSET_VALUE
          @puppet_server = "puppet" if @puppet_server == UNSET_VALUE
        end
      end
    end
  end
end
