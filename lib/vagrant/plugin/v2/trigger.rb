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
        # @param [Vagrant::Environment] env Vagrant environment
        # @param [Kernel_V2::TriggerConfig] config Trigger configuration
        # @param [Vagrant::Machine] machine Active Machine
        # @param [Vagrant::UI] ui Class for printing messages to user
        def initialize(env, config, machine, ui)
          @env        = env
          @config     = config
          @machine    = machine
          @ui         = ui

          @logger = Log4r::Logger.new("vagrant::trigger::#{self.class.to_s.downcase}")
        end

        # Fires all triggers, if any are defined for the named type and guest. Returns early
        # and logs a warning if the community plugin `vagrant-triggers` is installed
        #
        # @param [Symbol] name Name of `type` thing to fire trigger on
        # @param [Symbol] stage :before or :after
        # @param [String] guest The guest that invoked firing the triggers
        # @param [Symbol] type Type of trigger to fire (:action, :hook, :command)
        def fire(name, stage, guest, type, all: false)
          if community_plugin_detected?
            @logger.warn("Community plugin `vagrant-triggers detected, so core triggers will not fire")
            return
          end

          return @logger.warn("Name given is nil, no triggers will fire") if !name
          return @logger.warn("Name given cannot be symbolized, no triggers will fire") if
            !name.respond_to?(:to_sym)

          name = name.to_sym

          # get all triggers matching action
          triggers = find(name, stage, guest, type, all: all)

          if !triggers.empty?
            @logger.info("Firing trigger for #{type} #{name} on guest #{guest}")
            @ui.info(I18n.t("vagrant.trigger.start", type: type, stage: stage, name: name))
            execute(triggers)
          end
        end

        # Find all triggers defined for the named type and guest.
        #
        # @param [Symbol] name Name of `type` thing to fire trigger on
        # @param [Symbol] stage :before or :after
        # @param [String] guest The guest that invoked firing the triggers
        # @param [Symbol] type Type of trigger to fire
        # @return [Array]
        def find(name, stage, guest, type, all: false)
          triggers = nil
          name = nameify(name)

          if stage == :before
            triggers = config.before_triggers.select do |t|
              (all && t.command.respond_to?(:to_sym) && t.command.to_sym == :all && !t.ignore.include?(name.to_sym)) ||
                (type == :hook && matched_hook?(t.command, name)) ||
                nameify(t.command) == name
            end
          elsif stage == :after
            triggers = config.after_triggers.select do |t|
              (all && t.command.respond_to?(:to_sym) && t.command.to_sym == :all && !t.ignore.include?(name.to_sym)) ||
                (type == :hook && matched_hook?(t.command, name)) ||
                nameify(t.command) == name
            end
          else
            raise Errors::TriggersNoStageGiven,
              name: name,
              stage: stage,
              type: type,
              guest_name: guest
          end

          filter_triggers(triggers, guest, type)
        end

        protected

        # Convert object into name
        #
        # @param [Object, Class] object Object to name
        # @return [String]
        def nameify(object)
          if object.is_a?(Class)
            object.name.to_s
          else
            object.to_s
          end
        end

        #-------------------------------------------------------------------
        # Internal methods, don't call these.
        #-------------------------------------------------------------------

        # Generate all valid lookup keys for given action key
        #
        # @param [Class, String] key Base key for generation
        # @return [Array<String>] all valid keys
        def matched_hook?(key, subject)
          subject = nameify(subject)
          Vagrant.plugin("2").manager.generate_hook_keys(key).any? do |k|
            k == subject
          end
        end

        # Looks up if the community plugin `vagrant-triggers` is installed
        # and also caches the result
        #
        # @return [Boolean]
        def community_plugin_detected?
          if !defined?(@_triggers_enabled)
            plugins = Vagrant::Plugin::Manager.instance.installed_plugins
            @_triggers_enabled = plugins.keys.include?("vagrant-triggers")
          end
          @_triggers_enabled
        end

        # Filters triggers to be fired based on configured restraints
        #
        # @param [Array] triggers An array of triggers to be filtered
        # @param [String] guest_name The name of the current guest
        # @param [Symbol] type The type of trigger (:command or :type)
        # @return [Array] The filtered array of triggers
        def filter_triggers(triggers, guest_name, type)
          # look for only_on trigger constraint and if it doesn't match guest
          # name, throw it away also be sure to preserve order
          filter = triggers.dup

          filter.each do |trigger|
            index = nil
            match = false
            if trigger.only_on
              trigger.only_on.each do |o|
                if o.match(guest_name.to_s)
                  # trigger matches on current guest, so we're fine to use it
                  match = true
                  break
                end
              end
              # no matches found, so don't use trigger for guest
              index = triggers.index(trigger) unless match == true
            end

            if trigger.type != type
              index = triggers.index(trigger)
            end

            if index
              @logger.debug("Trigger #{trigger.id} will be ignored for #{guest_name}")
              triggers.delete_at(index)
            end
          end

          return triggers
        end

        # Execute all triggers in the given array
        #
        # @param [Array] triggers An array of triggers to be fired
        def execute(triggers)
          # ensure on_error is respected by exiting or continuing
          triggers.each do |trigger|
            @logger.debug("Running trigger #{trigger.id}...")

            if trigger.name
              @ui.info(I18n.t("vagrant.trigger.fire_with_name",
                                      name: trigger.name))
            else
              @ui.info(I18n.t("vagrant.trigger.fire"))
            end

            if trigger.info
              info(trigger.info)
            end

            if trigger.warn
              warn(trigger.warn)
            end

            if trigger.abort
              trigger_abort(trigger.abort)
            end

            if trigger.run
              run(trigger.run, trigger.on_error, trigger.exit_codes)
            end

            if trigger.run_remote
              run_remote(trigger.run_remote, trigger.on_error, trigger.exit_codes)
            end

            if trigger.ruby_block
              execute_ruby(trigger.ruby_block)
            end
          end
        end

        # Prints the given message at info level for a trigger
        #
        # @param [String] message The string to be printed
        def info(message)
          @ui.info(message)
        end

        # Prints the given message at warn level for a trigger
        #
        # @param [String] message The string to be printed
        def warn(message)
          @ui.warn(message)
        end

        # Runs a script on a guest
        #
        # @param [Provisioners::Shell::Config] config A Shell provisioner config
        def run(config, on_error, exit_codes)
          if config.inline
            if Vagrant::Util::Platform.windows?
              cmd = config.inline
            else
              cmd = Shellwords.split(config.inline)
            end

            @ui.detail(I18n.t("vagrant.trigger.run.inline", command: config.inline))
          else
            cmd = File.expand_path(config.path, @env.root_path).shellescape
            args = Array(config.args)
            cmd << " #{args.join(' ')}" if !args.empty?
            cmd = Shellwords.split(cmd)

            @ui.detail(I18n.t("vagrant.trigger.run.script", path: config.path))
          end

          # Pick an execution method to run the script or inline string with
          # Default to Subprocess::Execute
          exec_method = Vagrant::Util::Subprocess.method(:execute)

          if Vagrant::Util::Platform.windows?
            if config.inline
              exec_method = Vagrant::Util::PowerShell.method(:execute_inline)
            else
              exec_method = Vagrant::Util::PowerShell.method(:execute)
            end
          end

          begin
            result = exec_method.call(*cmd, :notify => [:stdout, :stderr]) do |type,data|
              options = {}
              case type
              when :stdout
                options[:color] = :green if !config.keep_color
              when :stderr
                options[:color] = :red if !config.keep_color
              end

              @ui.detail(data, options)
            end
            if !exit_codes.include?(result.exit_code)
              raise Errors::TriggersBadExitCodes,
                code: result.exit_code
            end
          rescue => e
            @ui.error(I18n.t("vagrant.errors.triggers_run_fail"))
            @ui.error(e.message)

            if on_error == :halt
              @logger.debug("Trigger run encountered an error. Halting on error...")
              raise e
            else
              @logger.debug("Trigger run encountered an error. Continuing on anyway...")
              @ui.warn(I18n.t("vagrant.trigger.on_error_continue"))
            end
          end
        end

        # Runs a script on the guest
        #
        # @param [ShellProvisioner/Config] config A Shell provisioner config
        def run_remote(config, on_error, exit_codes)
          if !@machine
            # machine doesn't even exist.
            if on_error == :halt
              raise Errors::TriggersGuestNotExist
            else
              @ui.warn(I18n.t("vagrant.errors.triggers_guest_not_exist"))
              @ui.warn(I18n.t("vagrant.trigger.on_error_continue"))
              return
            end
          elsif @machine.state.id != :running
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

        # Exits Vagrant immediately
        #
        # @param [Integer] code Code to exit Vagrant on
        def trigger_abort(exit_code)
          if Thread.current[:batch_parallel_action]
            @ui.warn(I18n.t("vagrant.trigger.abort_threaded"))
            @logger.debug("Trigger abort within parallel batch action. " \
              "Setting exit code and terminating.")
            Thread.current[:exit_code] = exit_code
            Thread.current.terminate
          else
            @ui.warn(I18n.t("vagrant.trigger.abort"))
            @logger.debug("Trigger abort within non-parallel action, exiting directly")
            Process.exit!(exit_code)
          end
        end

        # Calls the given ruby block for execution
        #
        # @param [Proc] ruby_block
        def execute_ruby(ruby_block)
          ruby_block.call(@env, @machine)
        end
      end
    end
  end
end
