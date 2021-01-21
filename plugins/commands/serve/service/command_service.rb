module VagrantPlugins
  module CommandServe
    module Service
      class CommandService < Hashicorp::Vagrant::Sdk::CommandService::Service
        def help_spec(*args)
          Hashicorp::Vagrant::Sdk::FuncSpec.new
        end

        def help(*args)
          options = command_options_for(args.last.metadata["plugin_name"])
          Hashicorp::Vagrant::Sdk::Command::HelpResp.new(
            help: options.help
          )
        end

        def synopsis_spec(*args)
          return Hashicorp::Vagrant::Sdk::FuncSpec.new
        end

        def synopsis(*args)
          plugin_name = args.last.metadata["plugin_name"]
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{plugin_name}"
          end
          klass = plugin.call
          Hashicorp::Vagrant::Sdk::Command::SynopsisResp.new(
            synopsis: klass.synopsis
          )
        end

        def flags_spec(*args)
          Hashicorp::Vagrant::Sdk::FuncSpec.new
        end

        def flags(*args)
          options = command_options_for(args.last.metadata["plugin_name"])

          # Now we can build our list of flags
          flags = options.top.list.find_all { |o|
            o.is_a?(OptionParser::Switch)
          }.map { |o|
            Hashicorp::Vagrant::Sdk::Command::Flag.new(
              description: o.desc.join(" "),
              long_name: o.switch_name,
              short_name: o.short.first,
              type: o.is_a?(OptionParser::Switch::NoArgument) ?
                Hashicorp::Vagrant::Sdk::Command::Flag::Type::BOOL :
                Hashicorp::Vagrant::Sdk::Command::Flag::Type::STRING
            )
          }

          Hashicorp::Vagrant::Sdk::Command::FlagsResp.new(
            flags: flags
          )
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
          Hashicorp::Vagrant::Sdk::FuncSpec.new(
            args: [
              Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Args.TerminalUI",
                name: "",
              ),
            ],
            result: [
              Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Command.ExecuteResp",
                name: "",
              ),
            ],
          )
        end

        def execute(req, ctx)
          plugin_name = ctx.metadata["plugin_name"]
          if plugin_name.nil?
            raise "missing plugin name in context: #{ctx.metadata.inspect}"
          end
          raw_terminal = req.args.first.value.value
          ui_client = Client::TerminalClient.terminal_arg_to_terminal_ui(raw_terminal)
          ui = Vagrant::UI::RemoteUI.new(ui_client)
          env = Vagrant::Environment.new(ui: ui, ui_class: Vagrant::UI::Silent)

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
          Hashicorp::Vagrant::Sdk::Command::ExecuteResp.new(
            exit_code: result
          )
        end
      end
    end
  end
end
