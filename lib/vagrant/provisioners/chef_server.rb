require 'pathname'

module Vagrant
  module Provisioners
    # This class implements provisioning via chef-client, allowing provisioning
    # with a chef server.
    class ChefServer < Chef
      register :chef_server

      class Config < Chef::Config
        attr_accessor :chef_server_url
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name
        attr_accessor :client_key_path
        attr_accessor :file_cache_path
        attr_accessor :file_backup_path

        def initialize
          super

          @validation_client_name = "chef-validator"
          @client_key_path = "/etc/chef/client.pem"
          @file_cache_path = "/srv/chef/file_store"
          @file_backup_path = "/srv/chef/cache"
        end

        def validate(errors)
          super

          errors.add(I18n.t("vagrant.config.chef.server_url_empty")) if !chef_server_url || chef_server_url.strip == ""
          errors.add(I18n.t("vagrant.config.chef.validation_key_path")) if !validation_key_path
          errors.add(I18n.t("vagrant.config.chef.run_list_empty")) if json[:run_list] && run_list.empty?
        end
      end

      def prepare
        raise ChefError, :server_validation_key_required if config.validation_key_path.nil?
        raise ChefError, :server_validation_key_doesnt_exist if !File.file?(validation_key_path)
        raise ChefError, :server_url_required if config.chef_server_url.nil?
      end

      def provision!
        verify_binary("chef-client")
        chown_provisioning_folder
        create_client_key_folder
        upload_validation_key
        setup_json
        setup_server_config
        run_chef_client
      end

      def create_client_key_folder
        env.ui.info I18n.t("vagrant.provisioners.chef.client_key_folder")
        path = Pathname.new(config.client_key_path)

        vm.ssh.execute do |ssh|
          ssh.sudo!("mkdir -p #{path.dirname}")
        end
      end

      def upload_validation_key
        env.ui.info I18n.t("vagrant.provisioners.chef.upload_validation_key")
        vm.ssh.upload!(validation_key_path, guest_validation_key_path)
      end

      def setup_server_config
        setup_config("chef_server_client", "client.rb", {
          :node_name => config.node_name,
          :chef_server_url => config.chef_server_url,
          :validation_client_name => config.validation_client_name,
          :validation_key => guest_validation_key_path,
          :client_key => config.client_key_path,
          :file_cache_path => config.file_cache_path,
          :file_backup_path => config.file_backup_path
        })
      end

      def run_chef_client
        commands = ["cd #{config.provisioning_path}",
                    "chef-client -c client.rb -j dna.json"]

        env.ui.info I18n.t("vagrant.provisioners.chef.running_client")
        vm.ssh.execute do |ssh|
          ssh.sudo!(commands) do |channel, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, commands)
            else
              env.ui.info("#{data}: #{type}")
            end
          end
        end
      end

      def validation_key_path
        File.expand_path(config.validation_key_path, env.root_path)
      end

      def guest_validation_key_path
        File.join(config.provisioning_path, "validation.pem")
      end
    end
  end
end
