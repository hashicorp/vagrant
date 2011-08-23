module Vagrant
  module Provisioners
    # This class is a base class where the common functionality shared between
    # chef-solo and chef-client provisioning are stored. This is **not an actual
    # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
    class Chef < Base
      include Util::Counter

      def initialize(env, config)
        super

        config.provisioning_path ||= "/tmp/vagrant-chef-#{get_and_update_counter(:provisioning_path)}"
      end

      def prepare
        raise ChefError, :invalid_provisioner
      end

      def verify_binary(binary)
        vm.ssh.execute do |ssh|
          # Checks for the existence of chef binary and error if it
          # doesn't exist.
          ssh.sudo!("which #{binary}", :error_class => ChefError, :_key => :chef_not_detected, :binary => binary)
        end
      end

      # Returns the path to the Chef binary, taking into account the
      # `binary_path` configuration option.
      def chef_binary_path(binary)
        return binary if !config.binary_path
        return File.join(config.binary_path, binary)
      end

      def chown_provisioning_folder
        vm.ssh.execute do |ssh|
          ssh.sudo!("mkdir -p #{config.provisioning_path}")
          ssh.sudo!("chown #{env.config.ssh.username} #{config.provisioning_path}")
        end
      end

      def setup_config(template, filename, template_vars)
        config_file = TemplateRenderer.render(template, {
          :log_level => config.log_level.to_sym,
          :http_proxy => config.http_proxy,
          :http_proxy_user => config.http_proxy_user,
          :http_proxy_pass => config.http_proxy_pass,
          :https_proxy => config.https_proxy,
          :https_proxy_user => config.https_proxy_user,
          :https_proxy_pass => config.https_proxy_pass,
          :no_proxy => config.no_proxy
        }.merge(template_vars))

        vm.ssh.upload!(StringIO.new(config_file), File.join(config.provisioning_path, filename))
      end

      def setup_json
        env.ui.info I18n.t("vagrant.provisioners.chef.json")

        # Set up initial configuration
        data = {
          :config => env.config.to_hash,
          :directory => env.config.vm.shared_folders["v-root"][:guestpath],
        }

        # And wrap it under the "vagrant" namespace
        data = { :vagrant => data }

        # Merge with the "extra data" which isn't put under the
        # vagrant namespace by default
        data.merge!(config.merged_json)

        json = data.to_json

        vm.ssh.upload!(StringIO.new(json), File.join(config.provisioning_path, "dna.json"))
      end
    end

    class Chef < Base
      class ChefError < Errors::VagrantError
        error_namespace("vagrant.provisioners.chef")
      end
    end

    class Chef < Base
      # This is the configuration which is available through `config.chef`
      class Config < Vagrant::Config::Base
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
        attr_writer :run_list

        def initialize
          @provisioning_path = nil
          @log_level = :info
          @json = {}
          @http_proxy = nil
          @http_proxy_user = nil
          @http_proxy_pass = nil
          @https_proxy = nil
          @https_proxy_user = nil
          @https_proxy_pass = nil
          @no_proxy = nil
          @binary_path = nil
          @binary_env = nil
          @run_list = nil
        end

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
