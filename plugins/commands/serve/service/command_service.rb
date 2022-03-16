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

            cmd_klass = plugin.call
            cmd_args = req.command_args.to_a[1..] + arguments.value
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
                long_name: o.switch_name.to_s.gsub(/^-/, ''),
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

          SDK::Command::CommandInfo.new(
            name: command_name,
            help: hlp_msg,
            flags: flags,
            synopsis: synopsis,
            subcommands: subcommands
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
