require 'fileutils'
require 'log4r'
require 'shellwords'

require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")
require "vagrant/util/subprocess"
require "vagrant/util/platform"
require "vagrant/util/powershell"

module Vagrant
  module Plugin
    module V2
      class Trigger
        # @return [Kernel_V2::Config::Trigger]
        attr_reader :config

        # This class is responsible for setting up basic triggers that were
        # defined inside a Vagrantfile.
        #
        # @param [Object] env Vagrant environment
        # @param [Object] config Trigger configuration
        # @param [Object] machine Active Machine
        def initialize(env, config, machine)
          @env        = env
          @config     = config
          @machine    = machine

          @logger = Log4r::Logger.new("vagrant::trigger::#{self.class.to_s.downcase}")
        end

        # Fires all triggers, if any are defined for the action and guest
        #
        # @param [Symbol] action Vagrant command to fire trigger on
        # @param [Symbol] stage :before or :after
        # @param [String] guest_name The guest that invoked firing the triggers
        def fire_triggers(action, stage, guest_name)
          # get all triggers matching action
          triggers = []
          if stage == :before
            triggers = config.before_triggers.select do |t|
              t.command == action || (t.command == :all && !t.ignore.include?(action))
            end
          elsif stage == :after
            triggers = config.after_triggers.select do |t|
              t.command == action || (t.command == :all && !t.ignore.include?(action))
            end
          else
            raise Errors::TriggersNoStageGiven,
              action: action,
              stage: stage,
              guest_name: guest_name
          end

          triggers = filter_triggers(triggers, guest_name)

          if !triggers.empty?
            @logger.info("Firing trigger for action #{action} on guest #{guest_name}")
            @machine.ui.info(I18n.t("vagrant.trigger.start", stage: stage, action: action))
            fire(triggers, guest_name)
          end
        end

        protected

        #-------------------------------------------------------------------
        # Internal methods, don't call these.
        #-------------------------------------------------------------------

        # Filters triggers to be fired based on configured restraints
        #
        # @param [Array] triggers An array of triggers to be filtered
        # @param [String] guest_name The name of the current guest
        # @return [Array] The filtered array of triggers
        def filter_triggers(triggers, guest_name)
          # look for only_on trigger constraint and if it doesn't match guest
          # name, throw it away also be sure to preserve order
          filter = triggers.dup

          filter.each do |trigger|
            index = nil
            match = false
            if trigger.only_on
              trigger.only_on.each do |o|
                if o.match?(guest_name)
                  # trigger matches on current guest, so we're fine to use it
                  match = true
                  break
                end
              end
              # no matches found, so don't use trigger for guest
              index = triggers.index(trigger) unless match == true
            end

            if !index.nil?
              @logger.debug("Trigger #{trigger.id} will be ignored for #{guest_name}")
              triggers.delete_at(index)
            end
          end

          return triggers
        end

        # Fires off all triggers in the given array
        #
        # @param [Array] triggers An array of triggers to be fired
        def fire(triggers, guest_name)
          # ensure on_error is respected by exiting or continuing

          triggers.each do |trigger|
            @logger.debug("Running trigger #{trigger.id}...")

            if !trigger.name.nil?
              @machine.ui.info(I18n.t("vagrant.trigger.fire_with_name",
                                      name: trigger.name))
            else
              @machine.ui.info(I18n.t("vagrant.trigger.fire"))
            end

            if trigger.info
              info(trigger.info)
            end

            if trigger.warn
              warn(trigger.warn)
            end

            if trigger.run
              run(trigger.run, trigger.on_error)
            end

            if trigger.run_remote
              run_remote(trigger.run_remote, trigger.on_error)
            end
          end
        end

        # Prints the given message at info level for a trigger
        #
        # @param [String] message The string to be printed
        def info(message)
          @machine.ui.info(message)
        end

        # Prints the given message at warn level for a trigger
        #
        # @param [String] message The string to be printed
        def warn(message)
          @machine.ui.warn(message)
        end

        # Runs a script on a guest
        #
        # @param [Provisioners::Shell::Config] config A Shell provisioner config
        def run(config, on_error)
          if !config.inline.nil?
            cmd = Shellwords.split(config.inline)

            if Vagrant::Util::Platform.windows?
              powershell_exe = Vagrant::Util::PowerShell.executable
              cmd = Shellwords.split("#{powershell_exe} #{config.powershell_args} '#{cmd.join(' ')}'")
            end

            @machine.ui.detail(I18n.t("vagrant.trigger.run.inline", command: config.inline))
          else
            cmd = File.expand_path(config.path, @env.root_path)

            cmd << " #{config.args.join(' ' )}" if config.args

            if Vagrant::Util::Platform.windows?
              powershell_exe = Vagrant::Util::PowerShell.executable
              cmd = Shellwords.split("#{powershell_exe} #{config.powershell_args} #{cmd}")
            else
              cmd = Shellwords.split(cmd)
            end

            @machine.ui.detail(I18n.t("vagrant.trigger.run.script", path: config.path))
          end


          begin
            result = Vagrant::Util::Subprocess.execute(*cmd, :notify => [:stdout, :stderr]) do |type,data|
              options = {}
              case type
              when :stdout
                options[:color] = :green if !config.keep_color
              when :stderr
                options[:color] = :red if !config.keep_color
              end

              @machine.ui.detail(data, options)
            end
          rescue => e
            @machine.ui.error(I18n.t("vagrant.errors.triggers_run_fail"))
            @machine.ui.error(e.message)

            if on_error == :halt
              @logger.debug("Trigger run encountered an error. Halting on error...")
              raise e
            else
              @logger.debug("Trigger run encountered an error. Continuing on anyway...")
              @machine.ui.warn(I18n.t("vagrant.trigger.on_error_continue"))
            end
          end
        end

        # Runs a script on the guest
        #
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run_remote(config, on_error)
          unless @machine.state.id == :running
            if on_error == :halt
              raise Errors::TriggersGuestNotRunning,
                machine_name: @machine.name,
                state: @machine.state.id
            else
              @machine.ui.error(I18n.t("vagrant.errors.triggers_guest_not_running",
                                        machine_name: @machine.name,
                                        state: @machine.state.id))
              @machine.ui.warn(I18n.t("vagrant.trigger.on_error_continue"))
              return
            end
          end

          prov = VagrantPlugins::Shell::Provisioner.new(@machine, config)

          begin
            prov.provision
          rescue => e
            @machine.ui.error(I18n.t("vagrant.errors.triggers_run_fail"))

            if on_error == :halt
              @logger.debug("Trigger run encountered an error. Halting on error...")
              raise e
            else
              @logger.debug("Trigger run encountered an error. Continuing on anyway...")
              @machine.ui.error(e.message)
            end
          end
        end
      end
    end
  end
end
