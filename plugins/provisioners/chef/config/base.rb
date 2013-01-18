module VagrantPlugins
  module Chef
    module Config
      class Base < Vagrant.plugin("2", :config)
        # Shared config
        attr_accessor :node_name
        attr_accessor :provisioning_path
        attr_accessor :log_level
        attr_accessor :json
        attr_accessor :http_proxy
        attr_accessor :http_proxy_user
        attr_accessor :http_proxy_pass
        attr_accessor :https_proxy
        attr_accessor :https_proxy_user
        attr_accessor :https_proxy_pass
        attr_accessor :no_proxy
        attr_accessor :binary_path
        attr_accessor :binary_env
        attr_accessor :attempts
        attr_accessor :arguments
        attr_writer :run_list

        # Provide defaults in such a way that they won't override the instance
        # variable. This is so merging continues to work properly.
        def attempts; @attempts || 1; end
        def json; @json ||= {}; end
        def log_level; @log_level || :info; end

        # This returns the json that is merged with the defaults and the
        # user set data.
        def merged_json
          original = { :instance_role => "vagrant" }
          original[:run_list] = @run_list if @run_list
          original.merge(json || {})
        end

        # Returns the run list, but also sets it up to be empty if it
        # hasn't been defined already.
        def run_list
          @run_list ||= []
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

        def instance_variables_hash
          # Overridden so that the 'json' key could be removed, since its just
          # merged into the config anyways
          result = super
          result.delete("json")
          result
        end
      end
    end
  end
end
