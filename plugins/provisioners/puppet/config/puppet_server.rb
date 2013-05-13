module VagrantPlugins
  module Puppet
    module Config
      class PuppetServer < Vagrant.plugin("2", :config)
        attr_accessor :puppet_server
        attr_accessor :puppet_node
        attr_accessor :options
        attr_accessor :facter

        def facter; @facter ||= {}; end
        def puppet_server; @puppet_server || "puppet"; end
        def options; @options ||= []; end
      end
    end
  end
end
