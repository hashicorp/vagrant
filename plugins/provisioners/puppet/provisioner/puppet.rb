require "digest/md5"

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
          @expanded_module_paths   = @config.expanded_module_paths(root_path)

          # Setup the module paths
          @module_paths = []
          @expanded_module_paths.each_with_index do |path, _|
            key = Digest::MD5.hexdigest(path.to_s)
            @module_paths << [path, File.join(config.temp_dir, "modules-#{key}")]
          end

          folder_opts = {}
          folder_opts[:type] = @config.synced_folder_type if @config.synced_folder_type
          folder_opts[:owner] = "root" if !@config.synced_folder_type
          folder_opts[:args] = @config.synced_folder_args if @config.synced_folder_args
          folder_opts[:nfs__quiet] = true

          if @config.environment_path.is_a?(Array)
            # Share the environments directory with the guest
            if @config.environment_path[0].to_sym == :host
              root_config.vm.synced_folder(
                File.expand_path(@config.environment_path[1], root_path),
                environments_guest_path, folder_opts)
            end
          end
          if @config.manifest_file
            @manifest_file  = File.join(manifests_guest_path, @config.manifest_file)
            # Share the manifests directory with the guest
            if @config.manifests_path[0].to_sym == :host
              root_config.vm.synced_folder(
                File.expand_path(@config.manifests_path[1], root_path),
                manifests_guest_path, folder_opts)
            end
          end

          # Share the module paths
          @module_paths.each do |from, to|
            root_config.vm.synced_folder(from, to, folder_opts)
          end
        end

        def parse_environment_metadata
          # Parse out the environment manifest path since puppet apply doesnt do that for us.
          environment_conf = File.join(environments_guest_path, @config.environment, "environment.conf")
          if @machine.communicate.test("test -e #{environment_conf}", sudo: true)
            @machine.communicate.sudo("cat #{environment_conf}") do | type, data|
              if type == :stdout
                data.each_line do |line|
                  if line =~ /^\s*manifest\s+=\s+([^\s]+)/
                    @manifest_file = $1
                    @manifest_file.gsub! "$codedir", File.dirname(environments_guest_path)
                    @manifest_file.gsub! "$environment", @config.environment
                    if !@manifest_file.start_with? "/"
                      @manifest_file = File.join(environments_guest_path, @config.environment, @manifest_file)
                    end
                    @logger.debug("Using manifest from environment.conf: #{@manifest_file}")
                  end
                end
              end
            end
          end
        end

        def provision
          # If the machine has a wait for reboot functionality, then
          # do that (primarily Windows)
          if @machine.guest.capability?(:wait_for_reboot)
            @machine.guest.capability(:wait_for_reboot)
          end

          # In environment mode we still need to specify a manifest file, if its not, use the one from env config if specified.
          if !@manifest_file
            @manifest_file = "#{environments_guest_path}/#{@config.environment}/manifests"
            parse_environment_metadata
          end
          # Check that the shared folders are properly shared
          check = []
          if @config.manifests_path.is_a?(Array) && @config.manifests_path[0] == :host
            check << manifests_guest_path
          end
          if @config.environment_path.is_a?(Array) && @config.environment_path[0] == :host
            check << environments_guest_path
          end
          @module_paths.each do |host_path, guest_path|
            check << guest_path
          end

          # Make sure the temporary directory is properly set up
          if windows?
            tmp_command = "mkdir -p #{config.temp_dir}"
            comm_opts = { shell: :powershell}
          else
            tmp_command = "mkdir -p #{config.temp_dir}; chmod 0777 #{config.temp_dir}"
            comm_opts = {}
          end

          @machine.communicate.tap do |comm|
            comm.sudo(tmp_command, comm_opts)
          end

          verify_shared_folders(check)

          # Verify Puppet is installed and run it
          puppet_bin = "puppet"
          verify_binary(puppet_bin)

          # Upload Hiera configuration if we have it
          @hiera_config_path = nil
          if config.hiera_config_path
            local_hiera_path   = File.expand_path(config.hiera_config_path,
              @machine.env.root_path)
            @hiera_config_path = File.join(config.temp_dir, "hiera.yaml")
            @machine.communicate.upload(local_hiera_path, @hiera_config_path)
          end

          run_puppet_apply
        end

        def manifests_guest_path
          if config.manifests_path[0] == :host
            # The path is on the host, so point to where it is shared
            key = Digest::MD5.hexdigest(config.manifests_path[1])
            File.join(config.temp_dir, "manifests-#{key}")
          else
            # The path is on the VM, so just point directly to it
            config.manifests_path[1]
          end
        end

        def environments_guest_path
          if config.environment_path[0] == :host
            # The path is on the host, so point to where it is shared
            File.join(config.temp_dir, "environments")
          else
            # The path is on the VM, so just point directly to it
            config.environment_path[1]
          end
        end

        def verify_binary(binary)
          # Determine the command to use to test whether Puppet is available.
          # This is very platform dependent.
          test_cmd = "sh -c 'command -v #{binary}'"
          if windows?
            test_cmd = "where.exe #{binary}"
            if @config.binary_path
              test_cmd = "where.exe \"#{@config.binary_path}:#{binary}\""
            end
          end

          if !machine.communicate.test(test_cmd)
            @config.binary_path = "/opt/puppetlabs/bin/"
            @machine.communicate.sudo(
              "test -x /opt/puppetlabs/bin/#{binary}",
              error_class: PuppetError,
              error_key: :not_detected,
              binary: binary)
          end
        end

        def run_puppet_apply
          default_module_path = "/etc/puppet/modules"
          if windows?
            default_module_path = "/ProgramData/PuppetLabs/puppet/etc/modules"
          end

          options = [config.options].flatten
          module_paths = @module_paths.map { |_, to| to }
          if !@module_paths.empty?
            # Append the default module path
            module_paths << default_module_path

            # Add the command line switch to add the module path
            module_path_sep = windows? ? ";" : ":"
            options << "--modulepath '#{module_paths.join(module_path_sep)}'"
          end

          if @hiera_config_path
            options << "--hiera_config=#{@hiera_config_path}"
          end

          if !@machine.env.ui.color?
            options << "--color=false"
          end

          options << "--detailed-exitcodes"
          if config.environment_path
            options << "--environmentpath #{environments_guest_path}/"
            options << "--environment #{@config.environment}"
          end

          options << @manifest_file
          options = options.join(" ")

          # Build up the custom facts if we have any
          facter = nil
          if !config.facter.empty?
            facts = []
            config.facter.each do |key, value|
              facts << "FACTER_#{key}='#{value}'"
            end

            # If we're on Windows, we need to use the PowerShell style
            if windows?
              facts.map! { |v| "$env:#{v};" }
            end

            facter = facts.join(" ")
          end

          puppet_bin = "puppet"
          if @config.binary_path
            puppet_bin = File.join(@config.binary_path, puppet_bin)
          end

          env_vars = nil
          if !config.environment_variables.nil? && !config.environment_variables.empty?
            env_vars = config.environment_variables.map do |env_key, env_value|
              "#{env_key}=\"#{env_value}\""
            end

            if windows?
              env_vars.map! do |env_var_string|
                "$env:#{env_var_string}"
              end
            end

            env_vars = env_vars.join(" ")
          end

          command = [
            env_vars,
            facter,
            puppet_bin,
            "apply",
            options
          ].compact.map(&:to_s).join(" ")
          if config.working_directory
            if windows?
              command = "cd #{config.working_directory}; if ($?) \{ #{command} \}"
            else
              command = "cd #{config.working_directory} && #{command}"
            end
          end

          if config.environment_path
            @machine.ui.info(I18n.t(
              "vagrant.provisioners.puppet.running_puppet_env",
              environment: config.environment))
          else
            @machine.ui.info(I18n.t(
              "vagrant.provisioners.puppet.running_puppet",
              manifest: config.manifest_file))
          end

          opts = {
            elevated: true,
            error_class: Vagrant::Errors::VagrantError,
            error_key: :ssh_bad_exit_status_muted,
            good_exit: [0,2],
          }

          if windows?
            opts[:shell] = :powershell
          end
          @machine.communicate.sudo(command, opts) do |type, data|
            if !data.chomp.empty?
              @machine.ui.info(data.chomp)
            end
          end
        end

        def verify_shared_folders(folders)
          folders.each do |folder|
            @logger.debug("Checking for shared folder: #{folder}")
            if windows?
              testcommand = "Test-Path #{folder}"
              comm_opts = { shell: :powershell}
            else
              testcommand = "test -d #{folder}"
              comm_opts = { sudo: true}
            end

            if !@machine.communicate.test(testcommand, comm_opts)
              raise PuppetError, :missing_shared_folders
            end
          end
        end

        def windows?
          @machine.config.vm.communicator == :winrm || @machine.config.vm.communicator == :winssh
        end
      end
    end
  end
end
