module VagrantPlugins
  module CommandServe
    module Service
      class CommandService < Hashicorp::Vagrant::Sdk::CommandService::Service
        def help_spec(*args)
          Hashicorp::Vagrant::Sdk::FuncSpec.new
        end

        def help(*args)
          plugin_name = args.last.metadata["plugin_name"]
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{plugin_name}"
          end
          # klass = plugin.call
          Hashicorp::Vagrant::Sdk::Command::HelpResp.new(
            help: "No help information configured"
          )
        end

        def synopsis_spec(*args)
          return Hashicorp::Vagrant::Sdk::FuncSpec.new
          Hashicorp::Vagrant::Sdk::FuncSpec.new(
            name: "synopsis",
            result: [
              Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
                type: "hashicorp.vagrant.sdk.Command.SynopsisResp",
                name: ""
              )
            ]
          )
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
          plugin_name = args.last.metadata["plugin_name"]
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{plugin_name}"
          end
          # klass = plugin.call
          Hashicorp::Vagrant::Sdk::Command::FlagsResp.new(
            flags: "not implemented"
          )
        end
      end
    end
  end
end
