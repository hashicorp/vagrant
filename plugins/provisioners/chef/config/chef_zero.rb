require File.expand_path('../chef_solo', __FILE__)

module VagrantPlugins
  module Chef
    module Config
      class ChefZero < ChefSolo
        attr_accessor :clients_path
        attr_accessor :users_path
        
        def initialize
          super

          @clients_path = UNSET_VALUE
          @local_mode = true
          @users_path = UNSET_VALUE
        end

        def finalize!
          super

          @clients_path = [] if @clients_path == UNSET_VALUE
          @users_path = [] if @users_path == UNSET_VALUE

          # Make sure the path is an array.
          @clients_path = prepare_folders_config(@clients_path)
          @users_path = prepare_folders_config(@users_path)
        end

        def validate(machine)
          super 

          errors = _detected_errors
          errors.concat(validate_base(machine))

          { "chef zero provisioner" => errors }
        end
      end
    end
  end
end
