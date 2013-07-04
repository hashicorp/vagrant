module VagrantPlugins
  module Chef
    module Config
      class Base < Vagrant.plugin("2", :config)
        attr_accessor :arguments
        attr_accessor :attempts
        attr_accessor :binary_path
        attr_accessor :binary_env
        attr_accessor :custom_config_path
        attr_accessor :http_proxy
        attr_accessor :http_proxy_user
        attr_accessor :http_proxy_pass
        attr_accessor :https_proxy
        attr_accessor :https_proxy_user
        attr_accessor :https_proxy_pass
        attr_accessor :json
        attr_accessor :log_level
        attr_accessor :no_proxy
        attr_accessor :node_name
        attr_accessor :provisioning_path
        attr_accessor :run_list
        attr_accessor :file_cache_path
        attr_accessor :file_backup_path

        def initialize
          super

          @arguments         = UNSET_VALUE
          @attempts          = UNSET_VALUE
          @binary_path       = UNSET_VALUE
          @binary_env        = UNSET_VALUE
          @custom_config_path = UNSET_VALUE
          @http_proxy        = UNSET_VALUE
          @http_proxy_user   = UNSET_VALUE
          @http_proxy_pass   = UNSET_VALUE
          @https_proxy       = UNSET_VALUE
          @https_proxy_user  = UNSET_VALUE
          @https_proxy_pass  = UNSET_VALUE
          @log_level         = UNSET_VALUE
          @no_proxy          = UNSET_VALUE
          @node_name         = UNSET_VALUE
          @provisioning_path = UNSET_VALUE
          @file_cache_path   = UNSET_VALUE
          @file_backup_path  = UNSET_VALUE

          @json              = {}
          @run_list          = []
        end

        def finalize!
          @arguments         = nil if @arguments == UNSET_VALUE
          @attempts          = 1 if @attempts == UNSET_VALUE
          @binary_path       = nil if @binary_path == UNSET_VALUE
          @binary_env        = nil if @binary_env == UNSET_VALUE
          @custom_config_path = nil if @custom_config_path == UNSET_VALUE
          @http_proxy        = nil if @http_proxy == UNSET_VALUE
          @http_proxy_user   = nil if @http_proxy_user == UNSET_VALUE
          @http_proxy_pass   = nil if @http_proxy_pass == UNSET_VALUE
          @https_proxy       = nil if @https_proxy == UNSET_VALUE
          @https_proxy_user  = nil if @https_proxy_user == UNSET_VALUE
          @https_proxy_pass  = nil if @https_proxy_pass == UNSET_VALUE
          @log_level         = :info if @log_level == UNSET_VALUE
          @no_proxy          = nil if @no_proxy == UNSET_VALUE
          @node_name         = nil if @node_name == UNSET_VALUE
          @provisioning_path = nil if @provisioning_path == UNSET_VALUE
          @file_backup_path  = "/var/chef/backup" if @file_backup_path == UNSET_VALUE
          @file_cache_path   = "/var/chef/cache" if @file_cache_path == UNSET_VALUE

          # Make sure the log level is a symbol
          @log_level = @log_level.to_sym
        end

        def merge(other)
          super.tap do |result|
            result.instance_variable_set(:@json, @json.merge(other.json))
            result.instance_variable_set(:@run_list, (@run_list + other.run_list))
          end
        end

        # Just like the normal configuration "validate" method except that
        # it returns an array of errors that should be merged into some
        # other error accumulator.
        def validate_base(machine)
          errors = []

          if @custom_config_path
            expanded = File.expand_path(@custom_config_path, machine.env.root_path)
            if !File.file?(expanded)
              errors << I18n.t("vagrant.config.chef.custom_config_path_missing")
            end
          end

          errors
        end

        # Adds a recipe to the run list
        def add_recipe(name)
          name = "recipe[#{name}]" unless name =~ /^recipe\[(.+?)\]$/
            run_list << name
        end

        # Adds a role to the run list
        def add_role(name)
          name = "role[#{name}]" unless name =~ /^role\[(.+?)\]$/
            run_list << name
        end
      end
    end
  end
end
