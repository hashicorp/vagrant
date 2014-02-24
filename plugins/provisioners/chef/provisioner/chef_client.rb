require 'chef-api'
require 'pathname'
require 'tempfile'

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
          upload_encrypted_data_bag_secret
          setup_json
          setup_server_config
          run_chef_client
          delete_encrypted_data_bag_secret
        end

        def cleanup
          return if !@config.delete_client && !@config.delete_node

          if !node_name
            @machine.env.ui.error(I18n.t(
              "vagrant.provisioners.chef.no_node_name_for_deleting"))
          elsif !cached_client_key_path.exist?
            @machine.env.ui.error(I18n.t(
              "vagrant.provisioners.chef.no_cached_client_key",
              node_name: node_name))
          else
            delete_from_chef_server(:node) if @config.delete_node
            delete_from_chef_server(:client) if @config.delete_client
            cached_client_key_path.delete
          end
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

        def setup_server_config
          setup_config("provisioners/chef_client/client", "client.rb", {
            :chef_server_url => @config.chef_server_url,
            :validation_client_name => @config.validation_client_name,
            :validation_key => guest_validation_key_path,
            :client_key => @config.client_key_path,
          })
        end

        def run_chef_client
          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          command_env = @config.binary_env ? "#{@config.binary_env} " : ""
          command_args = @config.arguments ? " #{@config.arguments}" : ""
          command = "#{command_env}#{chef_binary_path("chef-client")} " +
            "-c #{@config.provisioning_path}/client.rb " +
            "-j #{@config.provisioning_path}/dna.json #{command_args}"

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
            if exit_status == 0
              download_client_key
              return
            end
          end

          download_client_key

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end

        def validation_key_path
          File.expand_path(@config.validation_key_path, @machine.env.root_path)
        end

        def guest_validation_key_path
          File.join(@config.provisioning_path, "validation.pem")
        end

        def cached_client_key_path
          @machine.data_dir.parent.join("chef-client.pem")
        end

        def download_client_key
          return if !@config.delete_client && !@config.delete_node

          @machine.env.ui.info(I18n.t(
            "vagrant.provisioners.chef.download_client_key"))

          if !@machine.communicate.test("test -f #{@config.client_key_path}",
                                        sudo: true)
            @machine.env.ui.warn(I18n.t(
              "vagrant.provisioners.chef.no_client_key"))
            return
          end

          # We don't have permissions to scp the key directly, so we have to
          # copy it first for the vagrant user.
          # Echoing the key over stdin would get tricky too if PTY is enabled.
          @machine.communicate.tap do |comm|
            tmp_key = File.join(@config.provisioning_path, "tmp-client.pem")

            comm.sudo("cp #{@config.client_key_path} #{tmp_key}")
            comm.sudo("chown #{@machine.ssh_info[:username]} #{tmp_key}")
            comm.download(tmp_key, cached_client_key_path)
            comm.sudo("rm -f #{tmp_key}")
          end
        end

        def delete_from_chef_server(deletable)
          @machine.env.ui.info(I18n.t(
            "vagrant.provisioners.chef.delete_from_server",
            deletable: deletable, name: node_name))

          begin
            chefAPI.const_get(deletable.capitalize).delete(node_name)
          rescue ChefAPI::Error::ChefAPIError => e
            @machine.env.ui.error(I18n.t(
              "vagrant.chef_client_cleanup_failed",
              deletable: deletable,
              error: e))
          end
        end

        def chefAPI
          return @chefAPI if @chefAPI

          ChefAPI.configure do |config|
            config.endpoint = @config.chef_server_url
            config.client = node_name
            config.key = cached_client_key_path.to_s
            # TODO: proxy config
            # TODO: SSL config
          end
          @chefAPI = ChefAPI::Resource
        end
      end
    end
  end
end
