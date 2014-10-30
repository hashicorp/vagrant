module VagrantPlugins
  module Chef
    module Config
      class ChefApply < Vagrant.plugin("2", :config)
        extend Vagrant::Util::Counter

        # The raw recipe text (as a string) to execute via chef-apply.
        # @return [String]
        attr_accessor :recipe

        # The path (on the guest) where the uploaded apply recipe should be
        # written (/tmp/vagrant-chef-apply-#.rb).
        # @return [String]
        attr_accessor :upload_path

        # The Chef log level.
        # @return [String]
        attr_accessor :log_level

        def initialize
          @recipe  = UNSET_VALUE

          @log_level   = UNSET_VALUE
          @upload_path = UNSET_VALUE
        end

        def finalize!
          @recipe = nil if @recipe == UNSET_VALUE

          if @log_level == UNSET_VALUE
            @log_level = :info
          else
            @log_level = @log_level.to_sym
          end

          if @upload_path == UNSET_VALUE
            counter = self.class.get_and_update_counter(:chef_apply)
            @upload_path = "/tmp/vagrant-chef-apply-#{counter}"
          end
        end

        def validate(machine)
          errors = _detected_errors

          if missing(recipe)
            errors << I18n.t("vagrant.provisioners.chef.recipe_empty")
          end

          if missing(log_level)
            errors << I18n.t("vagrant.provisioners.chef.log_level_empty")
          end

          if missing(upload_path)
            errors << I18n.t("vagrant.provisioners.chef.upload_path_empty")
          end

          { "chef apply provisioner" => errors }
        end

        # Determine if the given string is "missing" (blank)
        # @return [true, false]
        def missing(obj)
          obj.to_s.strip.empty?
        end
      end
    end
  end
end
