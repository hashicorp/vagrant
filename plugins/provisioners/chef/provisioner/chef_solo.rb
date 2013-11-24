require File.expand_path("../base", __FILE__)

module VagrantPlugins
  module Chef
    module Provisioner
      # This class implements provisioning via chef-solo.
      class ChefSolo < Base
        attr_reader :environments_folders
        attr_reader :cookbook_folders
        attr_reader :role_folders
        attr_reader :data_bags_folders

        def initialize(machine, config)
          super
          @logger = Log4r::Logger.new("vagrant::provisioners::chef_solo")
        end

        def configure(root_config)
          @cookbook_folders  = expanded_folders(@config.cookbooks_path, "cookbooks")
          @role_folders      = expanded_folders(@config.roles_path, "roles")
          @data_bags_folders = expanded_folders(@config.data_bags_path, "data_bags")
          @environments_folders = expanded_folders(@config.environments_path, "environments")

          share_folders(root_config, "csc", @cookbook_folders)
          share_folders(root_config, "csr", @role_folders)
          share_folders(root_config, "csdb", @data_bags_folders)
          share_folders(root_config, "cse", @environments_folders)
        end

        def provision
          # Verify that the proper shared folders exist.
          check = []
          [@cookbook_folders, @role_folders, @data_bags_folders, @environments_folders].each do |folders|
            folders.each do |type, local_path, remote_path|
              # We only care about checking folders that have a local path, meaning
              # they were shared from the local machine, rather than assumed to
              # exist on the VM.
              check << remote_path if local_path
            end
          end

          chown_provisioning_folder
          verify_shared_folders(check)
          verify_binary(chef_binary_path("chef-solo"))
          upload_encrypted_data_bag_secret if @config.encrypted_data_bag_secret_key_path
          setup_json
          setup_solo_config
          run_chef_solo
        end

        def upload_encrypted_data_bag_secret
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")
          @machine.communicate.tap do |comm|
            comm.sudo("rm #{@config.encrypted_data_bag_secret}", :error_check => false)
            comm.upload(encrypted_data_bag_secret_key_path,
                        @config.encrypted_data_bag_secret)
          end
        end

        def setup_solo_config
          cookbooks_path = guest_paths(@cookbook_folders)
          roles_path = guest_paths(@role_folders).first
          data_bags_path = guest_paths(@data_bags_folders).first
          environments_path = guest_paths(@environments_folders).first
          setup_config("provisioners/chef_solo/solo", "solo.rb", {
            :node_name => @config.node_name,
            :cookbooks_path => cookbooks_path,
            :recipe_url => @config.recipe_url,
            :roles_path => roles_path,
            :data_bags_path => data_bags_path,
            :encrypted_data_bag_secret => @config.encrypted_data_bag_secret,
            :environments_path => environments_path,
            :environment => @config.environment,
          })
        end

        def run_chef_solo
          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          options = [
            "-c #{@config.provisioning_path}/solo.rb",
            "-j #{@config.provisioning_path}/dna.json"
          ]

          if !@machine.env.ui.is_a?(Vagrant::UI::Colored)
            options << "--no-color"
          end

          command_env = @config.binary_env ? "#{@config.binary_env} " : ""
          command_args = @config.arguments ? " #{@config.arguments}" : ""
          command = "#{command_env}#{chef_binary_path("chef-solo")} " +
            "#{options.join(" ")} #{command_args}"

          @config.attempts.times do |attempt|
            if attempt == 0
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo")
            else
              @machine.env.ui.info I18n.t("vagrant.provisioners.chef.running_solo_again")
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

        def encrypted_data_bag_secret_key_path
          File.expand_path(@config.encrypted_data_bag_secret_key_path, @machine.env.root_path)
        end

      end
    end
  end
end
