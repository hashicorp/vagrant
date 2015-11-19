require "vagrant/util/counter"

require_relative "base"

module VagrantPlugins
  module Chef
    module Config
      # This is the config base for Chef provisioners that need a full Chef
      # Runner object, like chef-solo or chef-client. For provisioners like
      # chef-apply, these options are not valid
      class BaseRunner < Base
        attr_accessor :arguments
        attr_accessor :attempts
        attr_accessor :custom_config_path
        attr_accessor :encrypted_data_bag_secret_key_path
        attr_accessor :environment
        attr_accessor :formatter
        attr_accessor :http_proxy
        attr_accessor :http_proxy_user
        attr_accessor :http_proxy_pass
        attr_accessor :https_proxy
        attr_accessor :https_proxy_user
        attr_accessor :https_proxy_pass
        attr_accessor :json
        attr_accessor :no_proxy
        attr_accessor :node_name
        attr_accessor :provisioning_path
        attr_accessor :run_list
        attr_accessor :file_cache_path
        attr_accessor :file_backup_path
        attr_accessor :verbose_logging
        attr_accessor :enable_reporting

        def initialize
          super

          @arguments          = UNSET_VALUE
          @attempts           = UNSET_VALUE
          @custom_config_path = UNSET_VALUE

          # /etc/chef/client.rb config options
          @encrypted_data_bag_secret_key_path = UNSET_VALUE
          @environment        = UNSET_VALUE
          @formatter          = UNSET_VALUE
          @http_proxy         = UNSET_VALUE
          @http_proxy_user    = UNSET_VALUE
          @http_proxy_pass    = UNSET_VALUE
          @https_proxy        = UNSET_VALUE
          @https_proxy_user   = UNSET_VALUE
          @https_proxy_pass   = UNSET_VALUE
          @no_proxy           = UNSET_VALUE
          @node_name          = UNSET_VALUE
          @provisioning_path  = UNSET_VALUE
          @file_cache_path    = UNSET_VALUE
          @file_backup_path   = UNSET_VALUE
          @verbose_logging    = UNSET_VALUE
          @enable_reporting   = UNSET_VALUE

          # Runner options
          @json     = {}
          @run_list = []
        end

        def finalize!
          super

          @arguments          = nil if @arguments == UNSET_VALUE
          @attempts           = 1   if @attempts == UNSET_VALUE
          @custom_config_path = nil if @custom_config_path == UNSET_VALUE
          @environment        = nil if @environment == UNSET_VALUE
          @formatter          = nil if @formatter == UNSET_VALUE
          @http_proxy         = nil if @http_proxy == UNSET_VALUE
          @http_proxy_user    = nil if @http_proxy_user == UNSET_VALUE
          @http_proxy_pass    = nil if @http_proxy_pass == UNSET_VALUE
          @https_proxy        = nil if @https_proxy == UNSET_VALUE
          @https_proxy_user   = nil if @https_proxy_user == UNSET_VALUE
          @https_proxy_pass   = nil if @https_proxy_pass == UNSET_VALUE
          @no_proxy           = nil if @no_proxy == UNSET_VALUE
          @node_name          = nil if @node_name == UNSET_VALUE
          @provisioning_path  = nil if @provisioning_path == UNSET_VALUE
          @file_backup_path   = nil if @file_backup_path == UNSET_VALUE
          @file_cache_path    = nil if @file_cache_path == UNSET_VALUE
          @verbose_logging    = false if @verbose_logging == UNSET_VALUE
          @enable_reporting   = true  if @enable_reporting == UNSET_VALUE

          if @encrypted_data_bag_secret_key_path == UNSET_VALUE
            @encrypted_data_bag_secret_key_path = nil
          end
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
          errors = super

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
