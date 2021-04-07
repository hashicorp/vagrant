require_relative "exception_logger"

module VagrantPlugins
  module CommandServe
    module Service
      class CommandService < SDK::CommandService::Service
        prepend VagrantPlugins::CommandServe::Service::ExceptionLogger

        [:help, :synopsis, :execute, :flags].each do |method|
          VagrantPlugins::CommandServe::Service::ExceptionLogger.log_exception method
        end

        def help_spec(*args)
          SDK::FuncSpec.new
        end

        def help(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            hlp = command_help_for(info.plugin_name)
            SDK::Command::HelpResp.new(
              help: hlp
            )
          end
        end

        def synopsis_spec(*args)
          return SDK::FuncSpec.new
        end

        def synopsis(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
            if !plugin
              raise "Failed to locate command plugin for: #{plugin_name}"
            end
            klass = plugin.call
            SDK::Command::SynopsisResp.new(
              synopsis: klass.synopsis
            )
          end
        end

        def flags_spec(*args)
          SDK::FuncSpec.new
        end

        def flags(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            options = command_options_for(info.plugin_name)

            if !options.nil?
              # Now we can build our list of flags
              flags = options.top.list.find_all { |o|
                o.is_a?(OptionParser::Switch)
              }.map { |o|
                SDK::Command::Flag.new(
                  description: o.desc.join(" "),
                  long_name: o.switch_name,
                  short_name: o.short.first,
                  type: o.is_a?(OptionParser::Switch::NoArgument) ?
                    SDK::Command::Flag::Type::BOOL :
                    SDK::Command::Flag::Type::STRING
                )
              }
            else
              flags = []
            end

            SDK::Command::FlagsResp.new(
              flags: flags
            )
          end
        end

        def command_options_for(name)
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{name}"
          end

          # Create a new anonymous class based on the command class
          # so we can modify the setup behavior
          klass = Class.new(plugin.call)

          # Update the option parsing to store the provided options, and then return
          # a nil value. The nil return will force the command to call help and not
          # actually execute anything.
          klass.class_eval do
            def parse_options(opts)
              Thread.current.thread_variable_set(:command_options, opts)
              nil
            end
          end

          env = Vagrant::Environment.new()
          # Execute the command to populate our options
          klass.new([], env).execute

          options = Thread.current.thread_variable_get(:command_options)

          # Clean our option data out of the thread
          Thread.current.thread_variable_set(:command_options, nil)

          # Send the options back
          options
        end

        def command_help_for(name)
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{name}"
          end
          # Create a new anonymous class based on the command class
          # so we can modify the setup behavior
          klass = Class.new(plugin.call)

          # Update the option parsing to store the provided options, and then return
          # a nil value. The nil return will force the command to call help and not
          # actually execute anything.
          klass.class_eval do
            def parse_options(opts)
              Thread.current.thread_variable_set(:command_options, opts)
              nil
            end
          end

          env = Vagrant::Environment.new()
          # Execute the command to populate our options
          cmd_plg = klass.new([], env)
          begin
            return cmd_plg.help
          rescue
            # The plugin does not have a help command.
            # That's fine, will get it from parse args
          end
          cmd_plg.execute

          options = Thread.current.thread_variable_get(:command_options)

          # Clean our option data out of the thread
          Thread.current.thread_variable_set(:command_options, nil)

          # Send the options back
          options.help
        end

        def execute_spec(req, ctx)
          SDK::FuncSpec.new(
            name: "execute_spec",
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.TerminalUI",
                name: "",
              ),
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Command.Arguments",
                name: "",
              )
            ],
            result: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Command.ExecuteResp",
                name: "",
              ),
            ],
          )
        end

        def execute(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            plugin_name = info.plugin_name
            raw_terminal = req.args.detect { |a|
              a.type == "hashicorp.vagrant.sdk.Args.TerminalUI"
            }&.value&.value
            raw_args = req.args.detect { |a|
              a.type == "hashicorp.vagrant.sdk.Command.Arguments"
            }&.value&.value

            arguments = SDK::Command::Arguments.decode(raw_args)
            ui_client = Client::Terminal.terminal_arg_to_terminal_ui(raw_terminal)

            ui = Vagrant::UI::RemoteUI.new(ui_client)
            env = Vagrant::Environment.new(ui: ui)

            plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
            if !plugin
              raise "Failed to locate command plugin for: #{plugin_name}"
            end
            cmd_klass = plugin.call
            cmd = cmd_klass.new(arguments.args.to_a, env)
            begin
              result = cmd.execute
            rescue => e
              raise e.message.tr("\n", " ") # + "\n" + e.backtrace.join("\n")
            end

            SDK::Command::ExecuteResp.new(
              exit_code: result.to_i
            )
          end
        end
      end
    end
  end
end
