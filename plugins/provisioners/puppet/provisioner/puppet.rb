require "log4r"

module VagrantPlugins
  module Puppet
    module Provisioner
      class PuppetError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.puppet")
      end

      class Puppet < Vagrant.plugin("2", :provisioner)
        def initialize(machine, config)
          super

          @logger = Log4r::Logger.new("vagrant::provisioners::puppet")
        end

        def configure(root_config)
          # Calculate the paths we're going to use based on the environment
          root_path = @machine.env.root_path
          @expanded_manifests_path = @config.expanded_manifests_path(root_path)
          @expanded_module_paths   = @config.expanded_module_paths(root_path)
          @manifest_file           = File.join(manifests_guest_path, @config.manifest_file)

          # Setup the module paths
          @module_paths = []
          @expanded_module_paths.each_with_index do |path, i|
            @module_paths << [path, File.join(config.temp_dir, "modules-#{i}")]
          end

          folder_opts = {}
          folder_opts[:nfs] = true if @config.nfs
          folder_opts[:owner] = "root" if !folder_opts[:nfs]

          # Share the manifests directory with the guest
          root_config.vm.synced_folder(
            @expanded_manifests_path, manifests_guest_path, folder_opts)

          # Share the module paths
          @module_paths.each do |from, to|
            root_config.vm.synced_folder(from, to, folder_opts)
          end
        end

        def provision
          # Check that the shared folders are properly shared
          check = [manifests_guest_path]
          @module_paths.each do |host_path, guest_path|
            check << guest_path
          end

          verify_shared_folders(check)

          # Verify Puppet is installed and run it
          verify_binary("puppet")

          # Make sure the temporary directory is properly set up
          @machine.communicate.tap do |comm|
            comm.sudo("mkdir -p #{config.temp_dir}")
            comm.sudo("chmod 0777 #{config.temp_dir}")
          end

          # Upload Hiera configuration if we have it
          @hiera_config_path = nil
          if config.hiera_config_path
            local_hiera_path   = File.expand_path(config.hiera_config_path, @machine.env.root_path)
            @hiera_config_path = File.join(config.temp_dir, "hiera.yaml")
            @machine.communicate.upload(local_hiera_path, @hiera_config_path)
          end

          run_puppet_apply
        end

        def manifests_guest_path
          File.join(config.temp_dir, "manifests")
        end

        def verify_binary(binary)
          @machine.communicate.sudo(
            "which #{binary}",
            :error_class => PuppetError,
            :error_key => :not_detected,
            :binary => binary)
        end

        def run_puppet_apply
          options = [config.options].flatten
          module_paths = @module_paths.map { |_, to| to }
          if !@module_paths.empty?
            # Prepend the default module path
            module_paths.unshift("/etc/puppet/modules")

            # Add the command line switch to add the module path
            options << "--modulepath '#{module_paths.join(':')}'"
          end

          if @hiera_config_path
            options << "--hiera_config=#{@hiera_config_path}"
          end

          if !@machine.env.ui.is_a?(Vagrant::UI::Colored)
            options << "--color=false"
          end

          options << "--manifestdir #{manifests_guest_path}"
          options << "--detailed-exitcodes"
          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = ""
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            facter = "#{facts.join(" ")} "
          end

          command = "#{facter}puppet apply #{options} || [ $? -eq 2 ]"
          if config.working_directory
            command = "cd #{config.working_directory} && #{command}"
          end

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => config.manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            if !data.empty?
              @machine.env.ui.info(data, :new_line => false, :prefix => false)
            end
          end
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if !@machine.communicate.test("test -d #{folder}", sudo: true)
              raise PuppetError, :missing_shared_folders
            end
          end
        end
      end
    end
  end
end
