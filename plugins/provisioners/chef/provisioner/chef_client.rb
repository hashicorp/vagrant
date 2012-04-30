require 'pathname'

require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Provisioner
      # This class implements provisioning via chef-client, allowing provisioning
      # with a chef server.
      class ChefClient < Base
        class Config < Base::Config
          attr_accessor :chef_server_url
          attr_accessor :validation_key_path
          attr_accessor :validation_client_name
          attr_accessor :client_key_path
          attr_accessor :file_cache_path
          attr_accessor :file_backup_path
          attr_accessor :environment
          attr_accessor :encrypted_data_bag_secret_key_path
          attr_accessor :encrypted_data_bag_secret

          # Provide defaults in such a way that they won't override the instance
          # variable. This is so merging continues to work properly.
          def validation_client_name; @validation_client_name || "chef-validator"; end
          def client_key_path; @client_key_path || "/etc/chef/client.pem"; end
          def file_cache_path; @file_cache_path || "/srv/chef/file_store"; end
          def file_backup_path; @file_backup_path || "/srv/chef/cache"; end
          def encrypted_data_bag_secret; @encrypted_data_bag_secret || "/tmp/encrypted_data_bag_secret"; end

          def validate(env, errors)
            super

            errors.add(I18n.t("vagrant.config.chef.server_url_empty")) if !chef_server_url || chef_server_url.strip == ""
            errors.add(I18n.t("vagrant.config.chef.validation_key_path")) if !validation_key_path
            errors.add(I18n.t("vagrant.config.chef.run_list_empty")) if @run_list && @run_list.empty?
          end
        end

        def self.config_class
          Config
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
          env[:ui].info I18n.t("vagrant.provisioners.chef.client_key_folder")
          path = Pathname.new(config.client_key_path)

          env[:vm].channel.sudo("mkdir -p #{path.dirname}")
        end

        def upload_validation_key
          env[:ui].info I18n.t("vagrant.provisioners.chef.upload_validation_key")
          env[:vm].channel.upload(validation_key_path, guest_validation_key_path)
        end

        def upload_encrypted_data_bag_secret
          env[:ui].info I18n.t("vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")
          env[:vm].channel.upload(encrypted_data_bag_secret_key_path,
                                  config.encrypted_data_bag_secret)
        end

        def setup_server_config
          setup_config("provisioners/chef_client/client", "client.rb", {
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

          config.attempts.times do |attempt|
            if attempt == 0
              env[:ui].info I18n.t("vagrant.provisioners.chef.running_client")
            else
              env[:ui].info I18n.t("vagrant.provisioners.chef.running_client_again")
            end

            exit_status = env[:vm].channel.sudo(command) do |type, data|
              # Output the data with the proper color based on the stream.
              color = type == :stdout ? :green : :red

              # Note: Be sure to chomp the data to avoid the newlines that the
              # Chef outputs.
              env[:ui].info(data.chomp, :color => color, :prefix => false)
            end

            # There is no need to run Chef again if it converges
            return if exit_status == 0
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end

        def validation_key_path
          File.expand_path(config.validation_key_path, env[:root_path])
        end

        def encrypted_data_bag_secret_key_path
          File.expand_path(config.encrypted_data_bag_secret_key_path, env[:root_path])
        end

        def guest_validation_key_path
          File.join(config.provisioning_path, "validation.pem")
        end
      end
    end
  end
end
