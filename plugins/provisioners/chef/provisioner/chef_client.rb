require 'pathname'
require 'vagrant/util/subprocess'

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Provisioner
      # This class implements provisioning via chef-client, allowing provisioning
      # with a chef server.
      class ChefClient < Base
        def configure(root_config)
          raise ChefError, :server_validation_key_required if @config.validation_key_path.nil?
          raise ChefError, :server_validation_key_doesnt_exist if !File.file?(validation_key_path)
          raise ChefError, :server_url_required if @config.chef_server_url.nil?
        end

        def provision
          verify_binary(chef_binary_path("chef-client"))
          chown_provisioning_folder
          create_client_key_folder
          upload_validation_key
          upload_encrypted_data_bag_secret if @config.encrypted_data_bag_secret_key_path
          setup_json
          setup_server_config
          run_chef_client
        end

        def cleanup
          delete_from_chef_server('client') if config.delete_client
          delete_from_chef_server('node') if config.delete_node
        end

        def create_client_key_folder
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.client_key_folder")
          path = Pathname.new(@config.client_key_path)

          @machine.communicate.sudo("mkdir -p #{path.dirname}")
        end

        def upload_validation_key
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.upload_validation_key")
          @machine.communicate.upload(validation_key_path, guest_validation_key_path)
        end

        def upload_encrypted_data_bag_secret
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")
          @machine.communicate.upload(encrypted_data_bag_secret_key_path,
                                  @config.encrypted_data_bag_secret)
        end

        def setup_server_config
          setup_config("provisioners/chef_client/client", "client.rb", {
            :node_name => @config.node_name,
            :chef_server_url => @config.chef_server_url,
            :validation_client_name => @config.validation_client_name,
            :validation_key => guest_validation_key_path,
            :client_key => @config.client_key_path,
            :environment => @config.environment,
            :encrypted_data_bag_secret => @config.encrypted_data_bag_secret
          })
        end

        def run_chef_client
          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          command_env = @config.binary_env ? "#{@config.binary_env} " : ""
          command_args = @config.arguments ? " #{@config.arguments}" : ""
          command = "#{command_env}#{chef_binary_path("chef-client")} -c #{@config.provisioning_path}/client.rb -j #{@config.provisioning_path}/dna.json #{command_args}"

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_client")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_client_again")
            end

            exit_status = @machine.communicate.sudo(command, :error_check => false) do |type, data|
              # Output the data with the proper color based on the stream.
              color = type == :stdout ? :green : :red
              @machine.env.ui.info(
                data, :color => color, :new_line => false, :prefix => false)
            end

            # There is no need to run Chef again if it converges
            return if exit_status == 0
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end

        def validation_key_path
          File.expand_path(@config.validation_key_path, @machine.env.root_path)
        end

        def encrypted_data_bag_secret_key_path
          File.expand_path(@config.encrypted_data_bag_secret_key_path, @machine.env.root_path)
        end

        def guest_validation_key_path
          File.join(@config.provisioning_path, "validation.pem")
        end

        def delete_from_chef_server(deletable)
          node_name = config.node_name || env[:vm].config.vm.host_name
          env[:ui].info(I18n.t(
            "vagrant.provisioners.chef.deleting_from_server",
            deletable: deletable, name: node_name))

          command = ["knife", deletable, "delete", "--yes", node_name]
          r = Vagrant::Util::Subprocess.execute(*command)
          if r.exit_code != 0
            env[:ui].error(I18n.t(
              "vagrant.chef_client_cleanup_failed",
              deletable: deletable,
              stdout: r.stdout,
              stderr: r.stderr))
          end
        end
      end
    end
  end
end
