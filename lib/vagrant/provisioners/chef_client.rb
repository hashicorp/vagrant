require 'pathname'

module Vagrant
  module Provisioners
    # This class implements provisioning via chef-client, allowing provisioning
    # with a chef server.
    class ChefClient < Chef
      register :chef_client

      class Config < Chef::Config
        attr_accessor :chef_server_url
        attr_accessor :validation_key_path
        attr_accessor :validation_client_name
        attr_accessor :client_key_path
        attr_accessor :file_cache_path
        attr_accessor :file_backup_path
        attr_accessor :environment
        attr_accessor :encrypted_data_bag_secret_key_path
        attr_accessor :encrypted_data_bag_secret

        def initialize
          super

          @validation_client_name = "chef-validator"
          @client_key_path = "/etc/chef/client.pem"
          @file_cache_path = "/srv/chef/file_store"
          @file_backup_path = "/srv/chef/cache"
          @encrypted_data_bag_secret_key_path = nil
          @encrypted_data_bag_secret = "/etc/chef/encrypted_data_bag_secret"
        end

        def validate(errors)
          super

          errors.add(I18n.t("vagrant.config.chef.server_url_empty")) if !chef_server_url || chef_server_url.strip == ""
          errors.add(I18n.t("vagrant.config.chef.validation_key_path")) if !validation_key_path
          errors.add(I18n.t("vagrant.config.chef.run_list_empty")) if @run_list && @run_list.empty?
        end
      end

      def prepare
        raise ChefError, :server_validation_key_required if config.validation_key_path.nil?
        raise ChefError, :server_validation_key_doesnt_exist if !File.file?(validation_key_path)
        raise ChefError, :server_url_required if config.chef_server_url.nil?
      end

      def provision!
        verify_binary(chef_binary_path("chef-client"))
        chown_provisioning_folder
        create_client_key_folder
        upload_validation_key
        upload_encrypted_data_bag_secret if config.encrypted_data_bag_secret_key_path
        setup_json
        setup_server_config
        run_chef_client
      end

      def create_client_key_folder
        env.ui.info I18n.t("vagrant.provisioners.chef.client_key_folder")
        path = Pathname.new(config.client_key_path)

        vm.ssh.execute do |ssh|
          ssh.sudo!("mkdir -p #{path.dirname}")
          ssh.exit
        end
      end

      def upload_validation_key
        env.ui.info I18n.t("vagrant.provisioners.chef.upload_validation_key")
        begin
          vm.ssh.upload!(validation_key_path, guest_validation_key_path)
        rescue ::Vagrant::Errors::VagrantError => e
        end
      end

      def upload_encrypted_data_bag_secret
        env.ui.info I18n.t("vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")
        begin
          vm.ssh.upload!(encrypted_data_bag_secret_key_path, config.encrypted_data_bag_secret)
        rescue ::Vagrant::Errors::VagrantError => e
        end
      end

      def setup_server_config
        setup_config("chef_server_client", "client.rb", {
          :node_name => config.node_name,
          :chef_server_url => config.chef_server_url,
          :validation_client_name => config.validation_client_name,
          :validation_key => guest_validation_key_path,
          :client_key => config.client_key_path,
          :file_cache_path => config.file_cache_path,
          :file_backup_path => config.file_backup_path,
          :environment => config.environment,
          :encrypted_data_bag_secret => config.encrypted_data_bag_secret
        })
      end

      def run_chef_client
        command_env = config.binary_env ? "#{config.binary_env} " : ""
        command = "#{command_env}#{chef_binary_path("chef-client")} -c #{config.provisioning_path}/client.rb -j #{config.provisioning_path}/dna.json"

        env.ui.info I18n.t("vagrant.provisioners.chef.running_client")
        vm.ssh.execute do |ssh|
          ssh.sudo!(command) do |channel, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, command)
            else
              env.ui.info("#{data}: #{type}")
            end
          end
          ssh.exit
        end
      end

      def validation_key_path
        File.expand_path(config.validation_key_path, env.root_path)
      end

      def encrypted_data_bag_secret_key_path
        File.expand_path(config.encrypted_data_bag_secret_key_path, env.root_path)
      end

      def guest_validation_key_path
        File.join(config.provisioning_path, "validation.pem")
      end
    end
  end
end
