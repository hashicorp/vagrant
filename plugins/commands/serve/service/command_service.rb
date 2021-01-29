module VagrantPlugins
  module CommandServe
    module Service
      class CommandService < SDK::CommandService::Service
        def help_spec(*args)
          SDK::FuncSpec.new
        end

        def help(req, ctx)
          ServiceInfo.with_info(ctx) do |info|
            options = command_options_for(info.plugin_name)
            SDK::Command::HelpResp.new(
              help: options.help
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

          # Execute the command to populate our options
          klass.new([], {}).execute

          options = Thread.current.thread_variable_get(:command_options)

          # Clean our option data out of the thread
          Thread.current.thread_variable_set(:command_options, nil)

          # Send the options back
          options
        end

        def execute_spec(req, ctx)
          SDK::FuncSpec.new(
            args: [
              SDK::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.TerminalUI",
                name: "",
              ),
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
            raw_terminal = req.args.first.value.value
            ui_client = Client::Terminal.terminal_arg_to_terminal_ui(raw_terminal)
            ui = Vagrant::UI::RemoteUI.new(ui_client)
            env = Vagrant::Environment.new(ui: ui)

            plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
            if !plugin
              raise "Failed to locate command plugin for: #{plugin_name}"
            end
            cmd_klass = plugin.call
            cmd = cmd_klass.new([], env)
            begin
              result = cmd.execute
            rescue => e
              raise e.to_s + "\n" + e.backtrace.join("\n")
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
