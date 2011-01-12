require 'pathname'

module Vagrant
  module Provisioners
    # This class implements provisioning via chef-client, allowing provisioning
    # with a chef server.
    class ChefServer < Chef
      register :chef_server

      def prepare
        raise ChefError, :server_validation_key_required if env.config.chef.validation_key_path.nil?
        raise ChefError, :server_validation_key_doesnt_exist if !File.file?(validation_key_path)
        raise ChefError, :server_url_required if env.config.chef.chef_server_url.nil?
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
        path = Pathname.new(env.config.chef.client_key_path)

        vm.ssh.execute do |ssh|
          ssh.exec!("sudo mkdir -p #{path.dirname}")
        end
      end

      def upload_validation_key
        env.ui.info I18n.t("vagrant.provisioners.chef.upload_validation_key")
        vm.ssh.upload!(validation_key_path, guest_validation_key_path)
      end

      def setup_server_config
        setup_config("chef_server_client", "client.rb", {
          :node_name => env.config.chef.node_name,
          :chef_server_url => env.config.chef.chef_server_url,
          :validation_client_name => env.config.chef.validation_client_name,
          :validation_key => guest_validation_key_path,
          :client_key => env.config.chef.client_key_path
        })
      end

      def run_chef_client
        command = "cd #{env.config.chef.provisioning_path} && sudo -E chef-client -c client.rb -j dna.json"

        env.ui.info I18n.t("vagrant.provisioners.chef.running_client")
        vm.ssh.execute do |ssh|
          ssh.exec!(command) do |channel, type, data|
            if type == :exit_status
              ssh.check_exit_status(data, command)
            else
              env.ui.info("#{data}: #{type}")
            end
          end
        end
      end

      def validation_key_path
        File.expand_path(env.config.chef.validation_key_path, env.root_path)
      end

      def guest_validation_key_path
        File.join(env.config.chef.provisioning_path, "validation.pem")
      end
    end
  end
end
