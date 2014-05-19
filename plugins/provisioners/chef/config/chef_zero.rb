require_relative "chef_solo"

module VagrantPlugins
  module Chef
    module Config
      class ChefZero < ChefSolo
        attr_accessor :nodes_path

        def initialize
          super

          @nodes_path = UNSET_VALUE
        end

        def finalize!
          super

          @nodes_path = [] if @nodes_path == UNSET_VALUE

          # Make sure the path is an array.
          @nodes_path = prepare_folders_config(@nodes_path)
        end

        def validate(machine)
          { "Chef Zero provisioner" => super["chef solo provisioner"] }
        end
      end
    end
  end
end
