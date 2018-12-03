require 'optparse'

module VagrantPlugins
  module CommandValidate
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "validates the Vagrantfile"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant validate [options]"
          o.separator ""
          o.separator "Validates a Vagrantfile config"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("-p", "--ignore-provider", "Ignores provider config options") do |p|
            options[:ignore_provider] = p
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        action_env = {}
        if options[:ignore_provider]
          action_env[:ignore_provider] = true
          tmp_data_dir = mockup_providers!
        end

        # Validate the configuration of all machines
        with_target_vms() do |machine|
          machine.action_raw(:config_validate, Vagrant::Action::Builtin::ConfigValidate, action_env)
        end

        @env.ui.info(I18n.t("vagrant.commands.validate.success"))

        # Success, exit status 0
        0
      ensure
        FileUtils.remove_entry tmp_data_dir if tmp_data_dir
      end

      protected

      # This method is required to bypass some of the provider checks that would
      # otherwise raise exceptions before Vagrant could load and validate a config.
      # It essentially ignores that there are no installed or usable prodivers so
      # that Vagrant can go along and validate the rest of the Vagrantfile and ignore
      # any provider blocks.
      #
      # return [String] tmp_data_dir - Temporary dir used to store guest metadata during validation
      def mockup_providers!
        require 'log4r'
        logger = Log4r::Logger.new("vagrant::validate")
        logger.debug("Overriding all registered provider classes for validate")

        # Without setting up a tmp Environment, Vagrant will completely
        # erase the local data dotfile and you can lose state after the
        # validate command completes.
        tmp_data_dir = Dir.mktmpdir("vagrant-validate-")
        @env = Vagrant::Environment.new(
          cwd: @env.cwd,
          home_path: @env.home_path,
          ui_class: @env.ui_class,
          vagrantfile_name: @env.vagrantfile_name,
          local_data_path: tmp_data_dir,
          data_dir: tmp_data_dir
        )

        Vagrant.plugin("2").manager.providers.each do |key, data|
          data[0].class_eval do
            def initialize(machine)
            end

            def machine_id_changed
            end

            def self.installed?
              true
            end

            def self.usable?(raise_error=false)
              true
            end

            def state
              state_id = Vagrant::MachineState::NOT_CREATED_ID
              short = :not_created
              long = :not_created
              Vagrant::MachineState.new(state_id, short, long)
            end
          end
        end
        tmp_data_dir
      end
    end
  end
end
