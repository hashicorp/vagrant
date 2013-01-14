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
            @module_paths << [path, File.join(config.pp_path, "modules-#{i}")]
          end

          # Share the manifests directory with the guest
          root_config.vm.share_folder(
            "manifests", manifests_guest_path, @expanded_manifests_path)

          # Share the module paths
          count = 0
          @module_paths.each do |from, to|
            # Sorry for the cryptic key here, but VirtualBox has a strange limit on
            # maximum size for it and its something small (around 10)
            root_config.vm.share_folder("v-pp-m#{count}", to, from)
            count += 1
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
          run_puppet_apply
        end

        def manifests_guest_path
          File.join(config.pp_path, "manifests")
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
          options << "--modulepath '#{module_paths.join(':')}'" if !@module_paths.empty?
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

          command = "cd #{manifests_guest_path} && #{facter}puppet apply #{options} --detailed-exitcodes || [ $? -eq 2 ]"

          @machine.env.ui.info I18n.t("vagrant.provisioners.puppet.running_puppet",
                                      :manifest => @manifest_file)

          @machine.communicate.sudo(command) do |type, data|
            data.chomp!
            @machine.env.ui.info(data, :prefix => false) if !data.empty?
          end
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if !@machine.communicate.test("test -d #{folder}")
              raise PuppetError, :missing_shared_folders
            end
          end
        end
      end
    end
  end
end
