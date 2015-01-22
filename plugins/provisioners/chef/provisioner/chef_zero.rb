require "log4r"

require_relative "chef_solo"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class implements provisioning via chef-zero.
      class ChefZero < ChefSolo
        attr_reader :node_folders

        def initialize(machine, config)
          super
          @logger = Log4r::Logger.new("vagrant::provisioners::chef_zero")
        end

        def configure(root_config)
          super

          @node_folders = expanded_folders(@config.nodes_path, "nodes")

          share_folders(root_config, "csn", @node_folders)
        end

        def provision
          super(:zero)
        end

        def solo_config
          super.merge(
            local_mode: true,
            node_path: guest_paths(@node_folders).first
          )
        end
      end
    end
  end
end
