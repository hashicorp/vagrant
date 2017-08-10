require "digest/md5"
require "securerandom"
require "set"

require "log4r"

require "vagrant/util/counter"

require_relative "chef_solo"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class implements provisioning via chef-zero.
      class ChefZero < ChefSolo
        def initialize(machine, config)
          super
          @logger = Log4r::Logger.new("vagrant::provisioners::chef_zero")
        end

        def provision
          install_chef
          # Verify that the proper shared folders exist.
          check = []
          @shared_folders.each do |type, local_path, remote_path|
            # We only care about checking folders that have a local path, meaning
            # they were shared from the local machine, rather than assumed to
            # exist on the VM.
            check << remote_path if local_path
          end

          chown_provisioning_folder
          verify_shared_folders(check)
          verify_binary(chef_binary_path("chef-client"))
          upload_encrypted_data_bag_secret
          setup_json
          setup_zero_config
          run_chef_zero
          delete_encrypted_data_bag_secret
        end

        def setup_zero_config
          setup_config("provisioners/chef_zero/zero", "client.rb", {
            local_mode: true,
            enable_reporting: false,
            cookbooks_path: guest_paths(@cookbook_folders),
            nodes_path: guest_paths(@node_folders),
            roles_path: guest_paths(@role_folders),
            data_bags_path: guest_paths(@data_bags_folders).first,
            environments_path: guest_paths(@environments_folders).first,
          })
        end

        def run_chef_zero
          if @config.run_list && @config.run_list.empty?
            @machine.ui.warn(I18n.t("vagrant.chef_run_list_empty"))
          end

          command = CommandBuilder.command(:client, @config,
            windows:    windows?,
            colored:    @machine.env.ui.color?,
            local_mode: true,
          )

          still_active = 259 #provisioner has asked chef to reboot 
          
          @config.attempts.times do |attempt|
            exit_status = 0
            while exit_status == 0 || exit_status == still_active 
              if @machine.guest.capability?(:wait_for_reboot)
                @machine.guest.capability(:wait_for_reboot)
              elsif attempt > 0
                sleep 10
                @machine.communicate.wait_for_ready(@machine.config.vm.boot_timeout)
              end
              if attempt == 0
                @machine.ui.info I18n.t("vagrant.provisioners.chef.running_zero")
              else
                @machine.ui.info I18n.t("vagrant.provisioners.chef.running_zero_again")
              end

              opts = { error_check: false, elevated: true }
              exit_status = @machine.communicate.sudo(command, opts) do |type, data|
                # Output the data with the proper color based on the stream.
                color = type == :stdout ? :green : :red

                data = data.chomp
                next if data.empty?

                @machine.ui.info(data, color: color)
              end

              # There is no need to run Chef again if it converges
              return if exit_status == 0
            end
          end

          # If we reached this point then Chef never converged! Error.
          raise ChefError, :no_convergence
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if !@machine.communicate.test("test -d #{folder}", sudo: true)
              raise ChefError, :missing_shared_folders
            end
          end
        end

        protected

        # Extracts only the remote paths from a list of folders
        def guest_paths(folders)
          folders.map { |parts| parts[2] }
        end
      end
    end
  end
end
