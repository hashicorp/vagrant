require 'log4r'

require 'pry'

module Vagrant
  module Plugin
    module V2
      class Trigger
        # @return [Kernel_V2/Config/Trigger]
        attr_reader :config

        # This class is responsible for setting up basic triggers that were
        # defined inside a Vagrantfile. It should take the Trigger config
        # and convert it to action hooks.
        #
        # @param [Object] env Vagrant environment
        # @param [Object] ui Machines ui object
        # @param [Object] config Trigger configuration
        def initialize(env, ui, config)
          @env = env
          @machine_ui = ui
          @config  = config

          @logger = Log4r::Logger.new("vagrant::trigger::#{self.class.to_s.downcase}")
        end

        # Fires all before triggers, if any are defined for the action and guest
        #
        # @param [Symbol] action Vagrant command to fire trigger on
        # @param [String] guest_name The guest that invoked firing the triggers
        def fire_before_triggers(action, guest_name)
          # get all triggers matching action
          triggers = config.before_triggers.select do |trigger|
            trigger.command == action
          end
          triggers = filter_triggers(triggers, guest_name)

          binding.pry
          unless triggers.empty?
            @logger.info("Firing trigger for action #{action} on guest #{guest_name}")
            # TODO I18N me
            @machine_ui.info("Running triggers before #{action}...")
            fire(triggers, guest_name)
          end
        end

        # Fires all after triggers, if any are defined for the action and guest
        #
        # @param [Symbol] action Vagrant command to fire trigger on
        # @param [String] guest_name The guest that invoked firing the triggers
        def fire_after_triggers(action, guest_name)
          triggers = []
          triggers = config.after_triggers.select do |trigger|
            trigger.command == action
          end
          triggers = filter_triggers(triggers, guest_name)

          binding.pry
          unless triggers.empty?
            @logger.info("Firing triggers for action #{action} on guest #{guest_name}")
            # TODO I18N me
            @machine_ui.info("Running triggers after #{action}...")
            fire(triggers, guest_name)
          end
        end

        protected

        #-------------------------------------------------------------------
        # Internal methods, don't call these.
        #-------------------------------------------------------------------

        # Filters triggers to be fired based on restraints
        #
        # @param [Array] triggers An array of triggers to be filtered
        # @return [Array] The filtered array of triggers
        def filter_triggers(triggers, guest_name)
          return triggers
        end

        # Fires off all triggers in the given array
        #
        # @param [Array] triggers An array of triggers to be fired
        def fire(triggers)
          # ensure on_error is respected by exiting or continuing

          triggers.each do |trigger|
          end
        end

        # Prints the given message at info level for a trigger
        #
        # @param [String] message The string to be printed
        def info(message)
          @machine_ui.info(message)
        end

        # Prints the given message at warn level for a trigger
        #
        # @param [String] message The string to be printed
        def warn(message)
          @machine_ui.warn(message)
        end

        # Runs a script on a guest
        #
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run(config)
          @logger.info("Running script on the host...")
        end

        # Runs a script on the host
        #
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run_remote(config)
          @logger.info("Running script on the guest...")
          # make sure guest actually exists, if not, display a WARNING
        end
      end
    end
  end
end
