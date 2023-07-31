# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require 'google/protobuf/well_known_types'

module VagrantPlugins
  module CommandServe
    module Service
      class CommandService < ProtoService(SDK::CommandService::Service)
        def command_info_spec(*args)
          SDK::FuncSpec.new
        end

        def command_info(req, ctx)
          with_info(ctx, broker: broker) do |info|
            command_info = collect_command_info(info.plugin_name, [])
            SDK::Command::CommandInfoResp.new(
              command_info: command_info,
            )
          end
        end

        def execute_spec(req, ctx)
          funcspec(
            args: [
              SDK::Args::TerminalUI,
              SDK::Args::Basis,
              SDK::Command::Arguments,
            ],
            result: SDK::Command::ExecuteResp,
          )
        end

        def execute(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name

            ui, basis, arguments = mapper.funcspec_map(
              req.spec,
              expect: [
                Vagrant::UI::Remote,
                SDK::Args::Basis,
                Type::CommandArguments
              ]
            )

            # We need a Vagrant::Environment to pass to the command. If we got a
            # Project from seeds we can use that to get an environment.
            # Otherwise we can initialize a barebones environment from the
            # Basis we received directly from the funcspec args above.
            if @seeds && @seeds.named["project"]
              logger.debug("loading a full environment from project found in seeds")
              project = mapper.unany(@seeds.named["project"])
              env = mapper.generate(project, type: Vagrant::Environment)
            else
              logger.debug("loading a minimal environment from basis provided in args")
              client = Client::Basis.load(basis, broker: broker)
              env = Vagrant::Environment.new(ui: ui, client: client)
            end

            plugin = Vagrant.plugin("2").local_manager.commands[plugin_name.to_sym].to_a.first
            if !plugin
              raise "Failed to locate command plugin for: #{plugin_name}"
            end

            # This bit does some sanitizing of input flags. Vagrant (core) accepts boolean flags 
            # as both --flag-name and --[no]-flag-name. Legacy Vagrant does not need to follow
            # this pattern, so there exists boolean flags that don't have a negative flag defined.
            # If a flag that is not defined in the legacy Vagrant api (but is defined in Vagrant core)
            # then providing this flag over the cli will cause an error when it is passed onto the 
            # Vagrant legacy side. This bit of code extracts all the flags defined in the Vagrant legacy
            # commands and ensures that no undefined flags are being passed in.
            # Get all the flags defined for the command
            available_flags = get_flag_set(info.plugin_name, req.command_args.to_a[1..])
            # Get all the flags passed in from the cli
            provided_flags = arguments.value
              .find_all { |t| t.start_with?("-") }
              .map { |m| m.gsub(/^[-]+/, "") }
              .map{ |m| m.split("=")[0]}
            # Build up a list of flags that are allowable. This list must not be prefixed with "no"
            # since the arguments.flag structure only holds to base name for the flag. eg. the form
            # of argument.flag is {"my-flag": true, "my-other-flag": false}.
            pass_flags = (available_flags & provided_flags).map{ |p| p.gsub(/^no-/, "")}

            # Filter out flags that are not included in the list of allowable flags
            arguments.flags.delete_if do |k,v|
              logger.debug("deleting flag #{k}") if !pass_flags.include?(k)
              !pass_flags.include?(k)
            end

            cmd_args = req.command_args.to_a[1..] + arguments.value
            cmd_klass = plugin.call
            cmd = cmd_klass.new(cmd_args, env)
            result = cmd.execute
            if !result.is_a?(Integer)
              result = 1
            end

            SDK::Command::ExecuteResp.new(
              exit_code: result.respond_to?(:to_i) ? result.to_i : 1
            )
          end
        end

        protected

        def get_flag_set(plugin_name, subcommand_names)
          logger.debug("collecting command information for #{plugin_name} #{subcommand_names}")
          options = command_options_for(plugin_name, subcommand_names)
          if options.nil?
            flags = []
          else
            flags = options.top.long.keys + options.top.short.keys
          end
          return flags
        end

        def collect_command_info(plugin_name, subcommand_names)
          logger.debug("collecting command information for #{plugin_name} #{subcommand_names}")
          options = command_options_for(plugin_name, subcommand_names)
          if options.nil?
            hlp_msg = ""
            flags = []
          else
            hlp_msg = options.banner
            # Now we can build our list of flags
            flags = options.top.list.find_all { |o|
              o.is_a?(OptionParser::Switch)
            }.map { |o|
              SDK::Command::Flag.new(
                description: o.desc.join(" "),
                long_name: o.switch_name.to_s.gsub(/^-/, '').gsub(/^no-/, ''),
                short_name: o.short.first.to_s.gsub(/^-/, ''),
                type: o.is_a?(OptionParser::Switch::NoArgument) ?
                  SDK::Command::Flag::Type::BOOL :
                  SDK::Command::Flag::Type::STRING
              )
            }
          end

          if subcommand_names.empty?
            plugin = Vagrant.plugin("2").local_manager.commands[plugin_name.to_sym].to_a.first
            if !plugin
              raise "Failed to locate command plugin for: #{plugin_name}"
            end
            klass = plugin.call
            synopsis = klass.synopsis
            command_name = plugin_name
          else
            synopsis = ""
            command_name = subcommand_names.last
          end
          subcommands = get_subcommands(plugin_name, subcommand_names)

          opts = Vagrant.plugin("2").local_manager.commands[plugin_name.to_sym].last

          SDK::Command::CommandInfo.new(
            name: command_name,
            help: hlp_msg,
            flags: flags,
            synopsis: synopsis,
            subcommands: subcommands,
            primary: opts[:primary],
          )
        end

        def get_subcommands(plugin_name, subcommand_names)
          logger.debug("collecting subcommands for #{plugin_name} #{subcommand_names}")
          subcommands = []
          cmds = subcommands_for(plugin_name, subcommand_names)
          if !cmds.nil?
            logger.debug("found subcommands #{cmds.keys}")
            cmds.keys.each do |subcmd|
              subnms = subcommand_names.dup
              subcommands << collect_command_info(plugin_name, subnms.append(subcmd.to_s))
            end
          else
            logger.debug("no subcommands found")
          end
          return subcommands
        end

        def augment_cmd_class(cmd_cls)
          # Create a new anonymous class based on the command class
          # so we can modify the setup behavior
          klass = Class.new(cmd_cls)

          klass.class_eval do
            def subcommands
              @subcommands
            end

            # Update the option parsing to store the provided options, and then return
            # a nil value. The nil return will force the command to call help and not
            # actually execute anything.
            def parse_options(opts)
              nil
            end
          end

          klass
        end

        def subcommands_for(name, subcommands = [])
          plugin = Vagrant.plugin("2").local_manager.commands[name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{name}"
          end

          # Create a new anonymous class based on the command class
          # so we can modify the setup behavior
          klass = augment_cmd_class(Class.new(plugin.call))

          # Execute the command to populate our options
          happy_klass = Class.new do
            def method_missing(*_)
              self
            end

            def to_hash
              {}
            end
          end

          cmd = klass.new(subcommands, happy_klass.new)
          # Go through the subcommands, looking for the command we actually want
          subcommands.each do |subcommand|
            cmd_cls = cmd.subcommands[subcommand.to_sym]
            cmd = augment_cmd_class(cmd_cls).new([], happy_klass.new)
          end

          cmd.subcommands
        end

        # Get command options
        #
        # @param [String] root name of the command
        # @param [String[]] list to subcommand
        # @return [String or OptionParser] if the command has more subcommands,
        #   then a String of the command help will be returned, otherwise,
        #   (an option parser should be available) the OptionParser for the command
        #    will be returned
        def command_options_for(name, subcommands = [])
          plugin = Vagrant.plugin("2").local_manager.commands[name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{name}"
          end

          # Create a new anonymous class based on the command class
          # so we can modify the setup behavior
          klass = augment_cmd_class(Class.new(plugin.call))

          # If we don't have a backup reference to the original
          # lets start with making one of those
          if !VagrantPlugins.const_defined?(:VagrantOriginalOptionParser)
            VagrantPlugins.const_set(:VagrantOriginalOptionParser, VagrantPlugins.const_get(:OptionParser))
          end

          # Now we need a customized class to get the new behavior
          # that we want
          optparse_klass = Class.new(::OptionParser) do
            def initialize(*args, &block)
              super(*args, &block)
              Thread.current.thread_variable_set(:command_options, self)
            end
          end

          # Now we need to swap out the constant. Swapping out constants
          # is bad, so we need to force our request through.
          VagrantPlugins.send(:remove_const, :OptionParser)
          VagrantPlugins.const_set(:OptionParser, optparse_klass)

          # Execute the command to populate our options
          happy_klass = Class.new do
            def method_missing(*_)
              self
            end
            def to_hash
              {}
            end
          end

          cmd = klass.new(subcommands, happy_klass.new)
          # Go through the subcommands, looking for the command we actually want
          subcommands.each do |subcommand|
            cmd_cls = cmd.subcommands[subcommand.to_sym]
            cmd = augment_cmd_class(cmd_cls).new([], happy_klass.new)
          end

          begin
            cmd.execute
          rescue Vagrant::Errors::VagrantError
            # ignore
          end

          options = Thread.current.thread_variable_get(:command_options)

          # Clean our option data out of the thread
          Thread.current.thread_variable_set(:command_options, nil)

          # And finally we restore our constants
          VagrantPlugins.send(:remove_const, :OptionParser)
          VagrantPlugins.const_set(:OptionParser, VagrantPlugins.const_get(:VagrantOriginalOptionParser))

          # Send the options back
          options
        end
      end
    end
  end
end
