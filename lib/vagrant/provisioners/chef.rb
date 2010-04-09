module Vagrant
  module Provisioners
    # This class is a base class where the common functinality shared between
    # chef-solo and chef-client provisioning are stored. This is **not an actual
    # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
    class Chef < Base
      # This is the configuration which is available through `config.chef`
      class ChefConfig < Vagrant::Config::Base
        # Chef server specific config
        attr_accessor :chef_server_url
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name
        attr_accessor :client_key_path
        attr_accessor :node_name

        # Chef solo specific config
        attr_accessor :cookbooks_path
        attr_accessor :roles_path

        # Shared config
        attr_accessor :provisioning_path
        attr_accessor :log_level
        attr_accessor :json

        def initialize
          @validation_client_name = "chef-validator"
          @client_key_path = "/etc/chef/client.pem"
          @node_name = "client"

          @cookbooks_path = "cookbooks"
          @roles_path = []
          @provisioning_path = "/tmp/vagrant-chef"
          @log_level = :info
          @json = {
            :instance_role => "vagrant",
            :run_list => ["recipe[vagrant_main]"]
          }
        end

        # Returns the run list for the provisioning
        def run_list
          json[:run_list]
        end

        # Sets the run list to the specified value
        def run_list=(value)
          json[:run_list] = value
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

        def to_json
          # Overridden so that the 'json' key could be removed, since its just
          # merged into the config anyways
          data = instance_variables_hash
          data.delete(:json)
          data.to_json
        end
      end

      # Tell the Vagrant configure class about our custom configuration
      Config.configures :chef, ChefConfig

      def prepare
        raise Actions::ActionException.new(:chef_base_invalid_provisioner)
      end

      def chown_provisioning_folder
        logger.info "Setting permissions on chef provisioning folder..."
        env.ssh.execute do |ssh|
          ssh.exec!("sudo mkdir -p #{env.config.chef.provisioning_path}")
          ssh.exec!("sudo chown #{env.config.ssh.username} #{env.config.chef.provisioning_path}")
        end
      end

      def setup_config(template, filename, template_vars)
        config_file = TemplateRenderer.render(template, {
          :log_level => env.config.chef.log_level.to_sym
        }.merge(template_vars))

        logger.info "Uploading chef configuration script..."
        env.ssh.upload!(StringIO.new(config_file), File.join(env.config.chef.provisioning_path, filename))
      end

      def setup_json
        logger.info "Generating chef JSON and uploading..."

        # Set up initial configuration
        data = {
          :config => env.config,
          :directory => env.config.vm.project_directory,
        }

        # And wrap it under the "vagrant" namespace
        data = { :vagrant => data }

        # Merge with the "extra data" which isn't put under the
        # vagrant namespace by default
        data.merge!(env.config.chef.json)

        json = data.to_json

        env.ssh.upload!(StringIO.new(json), File.join(env.config.chef.provisioning_path, "dna.json"))
      end
    end
  end
end
