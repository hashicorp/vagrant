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
          $stashed_opts = nil
          klass = Class.new(plugin.call)
          klass.class_eval { def parse_options(opts); $stashed_opts = opts; nil; end };
          klass.new(['-h'], {}).execute
          Hashicorp::Vagrant::Sdk::Command::HelpResp.new(
            help: $stashed_opts.help()
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
          plugin_name = args.last.metadata["plugin_name"]
          plugin = Vagrant::Plugin::V2::Plugin.manager.commands[plugin_name.to_sym].to_a.first
          if !plugin
            raise "Failed to locate command plugin for: #{plugin_name}"
          end
          # klass = Class.new(plugin.call)
          # klass.class_eval { 
          # }
          Hashicorp::Vagrant::Sdk::Command::FlagsResp.new(
            flags: [
              Hashicorp::Vagrant::Sdk::Command::Flag.new(
                long_name: "test", short_name: "t", 
                description: "does this even work?", default_value: "true",
                type: Hashicorp::Vagrant::Sdk::Command::Flag::Type::BOOL
              )
            ]
          )
        end
      end
    end
  end
end
