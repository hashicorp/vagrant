require 'tempfile'

require "log4r"
require "vagrant/util/counter"
require "vagrant/util/template_renderer"

module VagrantPlugins
  module Chef
    module Provisioner
      # This class is a base class where the common functionality shared between
      # chef-solo and chef-client provisioning are stored. This is **not an actual
      # provisioner**. Instead, {ChefSolo} or {ChefServer} should be used.
      class Base < Vagrant.plugin("2", :provisioner)
        extend Vagrant::Util::Counter
        include Vagrant::Util::Counter
        class ChefError < Vagrant::Errors::VagrantError
          error_namespace("vagrant.provisioners.chef")
        end

        include Vagrant::Util::Counter

        def initialize(machine, config)
          super

          config.provisioning_path ||= "/tmp/vagrant-chef-#{get_and_update_counter(:provisioning_path)}"
        end

        def verify_binary(binary)
          # Checks for the existence of chef binary and error if it
          # doesn't exist.
          @machine.communicate.sudo(
            "which #{binary}",
            :error_class => ChefError,
            :error_key => :chef_not_detected,
            :binary => binary)
        end

        # Returns the path to the Chef binary, taking into account the
        # `binary_path` configuration option.
        def chef_binary_path(binary)
          return binary if !@config.binary_path
          return File.join(@config.binary_path, binary)
        end

        def chown_provisioning_folder
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{@config.provisioning_path}")
            comm.sudo("chown #{@machine.ssh_info[:username]} #{@config.provisioning_path}")
          end
        end

        def setup_config(template, filename, template_vars)
          # If we have custom configuration, upload it
          remote_custom_config_path = nil
          if @config.custom_config_path
            expanded = File.expand_path(
              @config.custom_config_path, @machine.env.root_path)
            remote_custom_config_path = File.join(
              config.provisioning_path, "custom-config.rb")

            @machine.communicate.upload(expanded, remote_custom_config_path)
          end

          config_file = Vagrant::Util::TemplateRenderer.render(template, {
            :custom_configuration => remote_custom_config_path,
            :file_cache_path => @config.file_cache_path,
            :file_backup_path => @config.file_backup_path,
            :log_level        => @config.log_level.to_sym,
            :verbose_logging  => @config.verbose_logging,
            :http_proxy       => @config.http_proxy,
            :http_proxy_user  => @config.http_proxy_user,
            :http_proxy_pass  => @config.http_proxy_pass,
            :https_proxy      => @config.https_proxy,
            :https_proxy_user => @config.https_proxy_user,
            :https_proxy_pass => @config.https_proxy_pass,
            :no_proxy         => @config.no_proxy,
            :formatter        => @config.formatter
          }.merge(template_vars))

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(config_file)
          temp.close

          remote_file = File.join(config.provisioning_path, filename)
          @machine.communicate.tap do |comm|
            comm.sudo("rm #{remote_file}", :error_check => false)
            comm.upload(temp.path, remote_file)
          end
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            unless @machine.communicate.test("test -d #{folder}", sudo: true)
              fail ChefError, :missing_shared_folders
            end
          end
        end

        # Converts paths to a list of properly expanded paths with types.
        def expanded_folders(paths, appended_folder = nil)
          # Convert the path to an array if it is a string or just a single
          # path element which contains the folder location (:host or :vm)
          paths = [paths] if paths.is_a?(String) || paths.first.is_a?(Symbol)

          results = []
          paths.each do |type, path|
            # Create the local/remote path based on whether this is a host
            # or VM path.
            local_path = nil
            remote_path = nil
            if type == :host
              # Get the expanded path that the host path points to
              local_path = File.expand_path(path, @machine.env.root_path)

              if File.exist?(local_path)
                # Path exists on the host, setup the remote path
                remote_path = "#{@config.provisioning_path}/chef-local-#{get_and_update_counter(:cookbooks_path)}"
              else
                @machine.ui.warn(I18n.t('vagrant.provisioners.chef.cookbook_folder_not_found_warning',
                                        path: local_path.to_s))
                next
              end
            else
              # Path already exists on the virtual machine. Expand it
              # relative to where we're provisioning.
              remote_path = File.expand_path(path, @config.provisioning_path)

              # Remove drive letter if running on a windows host. This is a bit
              # of a hack but is the most portable way I can think of at the moment
              # to achieve this. Otherwise, Vagrant attempts to share at some crazy
              # path like /home/vagrant/c:/foo/bar
              remote_path = remote_path.gsub(/^[a-zA-Z]:/, '')
            end

            # If we have specified a folder name to append then append it
            remote_path += "/#{appended_folder}" if appended_folder

            # Append the result
            results << [type, local_path, remote_path]
          end

          results
        end

        # Shares the given folders with the given prefix. The folders should
        # be of the structure resulting from the `expanded_folders` function.
        def share_folders(root_config, prefix, folders)
          folders.each do |type, local_path, remote_path|
            if type == :host
              root_config.vm.synced_folder(
                local_path, remote_path,
                id: "v-#{prefix}-#{self.class.get_and_update_counter(:shared_folder)}",
                nfs: @config.nfs)
            end
          end
        end

        def setup_json
          @machine.env.ui.info I18n.t("vagrant.provisioners.chef.json")

          # Get the JSON that we're going to expose to Chef
          json = @config.json
          json[:run_list] = @config.run_list if !@config.run_list.empty?
          json = JSON.pretty_generate(json)

          # Create a temporary file to store the data so we
          # can upload it
          temp = Tempfile.new("vagrant")
          temp.write(json)
          temp.close

          remote_file = File.join(@config.provisioning_path, "dna.json")
          @machine.communicate.tap do |comm|
            comm.sudo("rm #{remote_file}", :error_check => false)
            comm.upload(temp.path, remote_file)
          end
        end

        # Extracts only the remote paths from a list of folders
        def guest_paths(folders)
          folders.map { |parts| parts[2] }
        end
      end
    end
  end
end
