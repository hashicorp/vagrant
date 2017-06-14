require "tempfile"

require_relative "../../../../lib/vagrant/util/presence"
require_relative "../../../../lib/vagrant/util/template_renderer"

require_relative "../installer"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class is a base class where the common functionality shared between
      # chef-solo and chef-client provisioning are stored. This is **not an actual
      # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
      class Base < Vagrant.plugin("2", :provisioner)
        include Vagrant::Util
        include Vagrant::Util::Presence

        class ChefError < Vagrant::Errors::VagrantError
          error_namespace("vagrant.provisioners.chef")
        end

        def initialize(machine, config)
          super

          @logger = Log4r::Logger.new("vagrant::provisioners::chef")

          if !present?(@config.node_name)
            # First attempt to get the node name from the hostname, and if that
            # is not present, generate/retrieve a random hostname.
            hostname = @machine.config.vm.hostname
            if present?(hostname)
              @machine.ui.info I18n.t("vagrant.provisioners.chef.using_hostname_node_name",
                hostname: hostname,
              )
              @config.node_name = hostname
            else
              cache = @machine.data_dir.join("chef_node_name")
              if !cache.exist?
                @machine.ui.info I18n.t("vagrant.provisioners.chef.generating_node_name")
                cache.open("w+") do |f|
                  f.write("vagrant-#{SecureRandom.hex(4)}")
                end
              end

              if cache.file?
                @logger.info("Loading cached node_name...")
                @config.node_name = cache.read.strip
              end
            end
          end
        end

        def install_chef
          return if !config.install

          @logger.info("Checking for Chef installation...")
          installer = Installer.new(@machine,
            product: config.product,
            channel: config.channel,
            version: config.version,
            omnibus_url: config.omnibus_url,
            force: config.install == :force,
            download_path:  config.installer_download_path
          )
          installer.ensure_installed
        end

        def verify_binary(binary)
          # Checks for the existence of chef binary and error if it
          # doesn't exist.
          if windows?
            command = "if ((&'#{binary}' -v) -Match 'Chef: *'){ exit 0 } else { exit 1 }"
          else
            command = "sh -c 'command -v #{binary}'"
          end

          @machine.communicate.sudo(
            command,
            error_class: ChefError,
            error_key: :chef_not_detected,
            binary: binary,
          )
        end

        # Returns the path to the Chef binary, taking into account the
        # `binary_path` configuration option.
        def chef_binary_path(binary)
          return binary if !@config.binary_path
          return File.join(@config.binary_path, binary)
        end

        def chown_provisioning_folder
          paths = [
            guest_provisioning_path,
            guest_file_backup_path,
            guest_file_cache_path,
          ]

          @machine.communicate.tap do |comm|
            paths.each do |path|
              if windows?
                comm.sudo("mkdir ""#{path}"" -f")
              else
                comm.sudo("mkdir -p #{path}")
                comm.sudo("chown -h #{@machine.ssh_info[:username]} #{path}")
              end
            end
          end
        end

        def setup_config(template, filename, template_vars)
          # If we have custom configuration, upload it
          remote_custom_config_path = nil
          if @config.custom_config_path
            expanded = File.expand_path(
              @config.custom_config_path, @machine.env.root_path)
            remote_custom_config_path = File.join(
              guest_provisioning_path, "custom-config.rb")

            @machine.communicate.upload(expanded, remote_custom_config_path)
          end

          config_file = TemplateRenderer.render(template, {
            custom_configuration: remote_custom_config_path,
            encrypted_data_bag_secret: guest_encrypted_data_bag_secret_key_path,
            environment:      @config.environment,
            file_cache_path:  guest_file_cache_path,
            file_backup_path: guest_file_backup_path,
            log_level:        @config.log_level.to_sym,
            node_name:        @config.node_name,
            verbose_logging:  @config.verbose_logging,
            enable_reporting: @config.enable_reporting,
            http_proxy:       @config.http_proxy,
            http_proxy_user:  @config.http_proxy_user,
            http_proxy_pass:  @config.http_proxy_pass,
            https_proxy:      @config.https_proxy,
            https_proxy_user: @config.https_proxy_user,
            https_proxy_pass: @config.https_proxy_pass,
            no_proxy:         @config.no_proxy,
            formatter:        @config.formatter
          }.merge(template_vars))

          # Create a temporary file to store the data so we can upload it.
          remote_file = File.join(guest_provisioning_path, filename)
          @machine.communicate.sudo(remove_command(remote_file), error_check: false)
          Tempfile.open("vagrant-chef-provisioner-config") do |f|
            f.binmode
            f.write(config_file)
            f.fsync
            f.close
            @machine.communicate.upload(f.path, remote_file)
          end
        end

        def setup_json
          @machine.ui.info I18n.t("vagrant.provisioners.chef.json")

          # Get the JSON that we're going to expose to Chef
          json = @config.json
          json[:run_list] = @config.run_list if @config.run_list &&
            !@config.run_list.empty?
          json = JSON.pretty_generate(json)

          # Create a temporary file to store the data so we can upload it.
          remote_file = File.join(guest_provisioning_path, "dna.json")
          @machine.communicate.sudo(remove_command(remote_file), error_check: false)
          Tempfile.open("vagrant-chef-provisioner-config") do |f|
            f.binmode
            f.write(json)
            f.fsync
            f.close
            @machine.communicate.upload(f.path, remote_file)
          end
        end

        def upload_encrypted_data_bag_secret
          remote_file = guest_encrypted_data_bag_secret_key_path
          return if !remote_file

          @machine.ui.info I18n.t(
            "vagrant.provisioners.chef.upload_encrypted_data_bag_secret_key")

          @machine.communicate.sudo(remove_command(remote_file), error_check: false)
          @machine.communicate.upload(encrypted_data_bag_secret_key_path, remote_file)
        end

        def delete_encrypted_data_bag_secret
          remote_file = guest_encrypted_data_bag_secret_key_path
          return if remote_file.nil?

          @machine.communicate.sudo(remove_command(remote_file), error_check: false)
        end

        def encrypted_data_bag_secret_key_path
          File.expand_path(@config.encrypted_data_bag_secret_key_path,
            @machine.env.root_path)
        end

        def guest_encrypted_data_bag_secret_key_path
          if @config.encrypted_data_bag_secret_key_path
            File.join(guest_provisioning_path, "encrypted_data_bag_secret_key")
          end
        end

        def guest_provisioning_path
          if !@config.provisioning_path.nil?
            return @config.provisioning_path
          end

          if windows?
            "C:/vagrant-chef"
          else
            "/tmp/vagrant-chef"
          end
        end

        def guest_file_backup_path
          if !@config.file_backup_path.nil?
            return @config.file_backup_path
          end

          if windows?
            "C:/chef/backup"
          else
            "/var/chef/backup"
          end
        end

        def guest_file_cache_path
          if !@config.file_cache_path.nil?
            return @config.file_cache_path
          end

          if windows?
            "C:/chef/cache"
          else
            "/var/chef/cache"
          end
        end

        def remove_command(path)
          if windows?
            "if (test-path ""#{path}"") {rm ""#{path}"" -force -recurse}"
          else
            "rm -f #{path}"
          end
        end

        def windows?
          @machine.config.vm.communicator == :winrm
        end
      end
    end
  end
end
