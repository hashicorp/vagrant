require "log4r"
require "vagrant"

module VagrantPlugins
  module CFEngine
    class Provisioner < Vagrant.plugin("2", :provisioner)
      def provision
        if @machine.config.vm.communicator == :winrm
          raise Vagrant::Errors::ProvisionerWinRMUnsupported,
            name: "cfengine"
        end

        @logger = Log4r::Logger.new("vagrant::plugins::cfengine")

        @logger.info("Checking for CFEngine installation...")
        handle_cfengine_installation

        if @config.files_path
          @machine.ui.info(I18n.t("vagrant.cfengine_installing_files_path"))
          install_files(Pathname.new(@config.files_path).expand_path(@machine.env.root_path))
        end

        handle_cfengine_bootstrap if @config.mode == :bootstrap

        if @config.mode == :single_run
          # Just let people know
          @machine.ui.info(I18n.t("vagrant.cfengine_single_run"))
        end

        if @config.run_file
          @machine.ui.info(I18n.t("vagrant.cfengine_single_run_execute"))
          path = Pathname.new(@config.run_file).expand_path(@machine.env.root_path)
          machine.communicate.upload(path.to_s, @config.upload_path)
          cfagent("-KI -f #{@config.upload_path}#{cfagent_classes_args}#{cfagent_extra_args}")
        end
      end

      protected

      # This runs cf-agent with the given arguments.
      def cfagent(args, options=nil)
        options ||= {}
        command = "/var/cfengine/bin/cf-agent #{args}"

        @machine.communicate.sudo(command, error_check: options[:error_check]) do |type, data|
          if [:stderr, :stdout].include?(type)
            # Output the data with the proper color based on the stream.
            color = type == :stdout ? :green : :red
            @machine.ui.info(
              data,
              color: color, new_line: false, prefix: false)
          end
        end
      end

      # Returns the arguments for the classes configuration if they are
      # set.
      #
      # @return [String]
      def cfagent_classes_args
        return "" if !@config.classes

        args = @config.classes.map { |c| "-D#{c}" }.join(" ")
        return " #{args}"
      end

      # Extra arguments for calles to cf-agent.
      #
      # @return [String]
      def cfagent_extra_args
        return "" if !@config.extra_agent_args
        return " #{@config.extra_agent_args}"
      end

      # This handles checking if the CFEngine installation needs to
      # be bootstrapped, and bootstraps if it does.
      def handle_cfengine_bootstrap
        @logger.info("Bootstrapping CFEngine...")
        if !@machine.guest.capability(:cfengine_needs_bootstrap, @config)
          @machine.ui.info(I18n.t("vagrant.cfengine_no_bootstrap"))
          return
        end

        # Needs bootstrap, let's determine the parameters
        policy_server_address = @config.policy_server_address
        if !policy_server_address
          policy_server_address = @machine.guest.capability(:read_ip_address)
          raise Vagrant::Errors::CFEngineCantAutodetectIP if !policy_server_address
          @machine.ui.info(I18n.t("vagrant.cfengine_detected_ip", address: policy_server_address))
        end

        @machine.ui.info(I18n.t("vagrant.cfengine_bootstrapping",
                                policy_server: policy_server_address))
        result = cfagent("--bootstrap #{policy_server_address}", error_check: false)
        raise Vagrant::Errors::CFEngineBootstrapFailed if result != 0

        # Policy hubs need to do additional things before they're ready
        # to accept agents. Force that run now...
        if @config.am_policy_hub
          @machine.ui.info(I18n.t("vagrant.cfengine_bootstrapping_policy_hub"))
          cfagent("-KI -f /var/cfengine/masterfiles/failsafe.cf#{cfagent_classes_args}")
          cfagent("-KI #{cfagent_classes_args}#{cfagent_extra_args}")
        end
      end

      # This handles verifying the CFEngine installation, installing it
      # if it was requested, and so on. This method will raise exceptions
      # if things are wrong.
      def handle_cfengine_installation
        if !@machine.guest.capability?(:cfengine_installed)
          @machine.ui.warn(I18n.t("vagrant.cfengine_cant_detect"))
          return
        end

        installed = @machine.guest.capability(:cfengine_installed)
        if !installed || @config.install == :force
          raise Vagrant::Errors::CFEngineNotInstalled if !@config.install

          @machine.ui.info(I18n.t("vagrant.cfengine_installing"))
          @machine.guest.capability(:cfengine_install, @config)

          if !@machine.guest.capability(:cfengine_installed)
            raise Vagrant::Errors::CFEngineInstallFailed
          end
        end
      end

      # This installs a set of files into the CFEngine folder within
      # the machine.
      #
      # @param [Pathname] local_path
      def install_files(local_path)
        @logger.debug("Copying local files to CFEngine: #{local_path}")
        @machine.communicate.sudo("rm -rf /tmp/cfengine-files")
        @machine.communicate.upload(local_path.to_s, "/tmp/cfengine-files")
        @machine.communicate.sudo("cp -R /tmp/cfengine-files/* /var/cfengine")
      end
    end
  end
end
