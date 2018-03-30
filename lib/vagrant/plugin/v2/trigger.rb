require 'log4r'
require 'shellwords'
require 'fileutils'

require "vagrant/util/subprocess"
require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")

#require 'pry'

module Vagrant
  module Plugin
    module V2
      class Trigger
        # @return [Kernel_V2/Config/Trigger]
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
            triggers = config.before_triggers.select { |t| t.command == action }
          elsif stage == :after
            triggers = config.after_triggers.select { |t| t.command == action }
          else
            # raise error, stage was not given
            # This is an internal error
            # TODO: Make sure this error exist
            raise Errors::Triggers::NoStageGiven,
              action: action,
              stage: stage,
              guest_name: guest_name
          end

          triggers = filter_triggers(triggers, guest_name)

          unless triggers.empty?
            @logger.info("Firing trigger for action #{action} on guest #{guest_name}")
            # TODO I18N me
            @machine.ui.info("Running triggers #{stage} #{action}...")
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
            if !trigger.only_on.nil?
              trigger.only_on.each do |o|
                if o.match?(guest_name)
                  index = triggers.index(trigger)
                end
              end
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

            # TODO: I18n me
            if !trigger.name.nil?
              @machine.ui.info("Running trigger: #{trigger.name}...")
            else
              @machine.ui.info("Running trigger...")
            end

            if !trigger.info.nil?
              @logger.debug("Executing trigger info message...")
              self.info(trigger.info)
            end

            if !trigger.warn.nil?
              @logger.debug("Executing trigger warn message...")
              self.warn(trigger.warn)
            end

            if !trigger.run.nil?
              @logger.debug("Executing trigger run script...")
              self.run(trigger.run, trigger.on_error)
            end

            if !trigger.run_remote.nil?
              @logger.debug("Executing trigger run_remote script on #{guest_name}...")
              self.run_remote(trigger.run_remote, trigger.on_error)
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
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run(config, on_error)
          # TODO: I18n me
          if !config.inline.nil?
            cmd = Shellwords.split(config.inline)
            @machine.ui.info("Executing local: Inline script")
          else
            cmd = File.expand_path(config.path, @env.root_path)
            FileUtils.chmod("+x", cmd) # TODO: what about windows
            @machine.ui.info("Executing local: File script #{config.path}")
          end

          begin
            # TODO: should we check config or command for sudo? And if so, WARN the user?
            result = Vagrant::Util::Subprocess.execute(*cmd, :notify => [:stdout, :stderr]) do |type,data|
              case type
              when :stdout
                @machine.ui.detail(data)
              when :stderr
                @machine.ui.error(data)
              end
            end
          rescue Exception => e
            # TODO: I18n me and write better message
            @machine.ui.error("Trigger run failed:")
            @machine.ui.error(e.message)

            if on_error == :halt
              @logger.debug("Trigger run encountered an error. Halting on error...")
              # Raise proper Vagrant error to avoid ugly stacktrace
              raise e
            else
              @logger.debug("Trigger run encountered an error. Continuing on anyway...")
            end
          end
        end

        # Runs a script on the host
        #
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run_remote(config, on_error)
          unless @machine.state.id == :running
            # TODO: I18n me, improve message, etc
            @machine.ui.error("Could not run remote script on #{@machine.name} because its state is #{@machine.state.id}")
            if on_error == :halt
              raise Errors::Triggers::RunRemoteGuestNotExist
            else
              @machine.ui.warn("Trigger configured to continue on error....")
              return
            end
          end

          prov = VagrantPlugins::Shell::Provisioner.new(@machine, config)

          begin
            prov.provision
          rescue Exception => e
            if on_error == :halt
              @logger.debug("Trigger run encountered an error. Halting on error...")
              raise e
            else
              @logger.debug("Trigger run encountered an error. Continuing on anyway...")
              # TODO: I18n me and write better message
              @machine.ui.error("Trigger run failed:")
              @machine.ui.error(e.message)
            end
          end
        end
      end
    end
  end
end
