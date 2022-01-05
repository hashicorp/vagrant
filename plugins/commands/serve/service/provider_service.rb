require 'vagrant/machine'
require 'vagrant/batch_action'
require 'vagrant/ui'

module VagrantPlugins
  module CommandServe
    module Service
      class ProviderService < SDK::ProviderService::Service
        include Util::ServiceInfo
        include Util::HasSeeds::Service

        prepend Util::HasMapper
        prepend Util::HasBroker
        prepend Util::HasLogger
        include Util::ExceptionLogger

        def usable(req, _unused_call)
          nil
        end

        def usable_spec(req, _unused_call)
          nil
        end

        def installed(req, _unused_call)
          nil
        end

        def installed_spec(req, _unused_call)
          nil
        end

        def init(req, _unused_call)
          nil
        end

        def init_spec(req, _unused_call)
          nil
        end

        def action_up(req, ctx)
          with_info(ctx, broker: broker) do |info|
            plugin_name = info.plugin_name
            ui, machine = mapper.funcspec_map(req.spec, expect: [Vagrant::UI::Remote, Vagrant::Machine])

            machine = Client::Target::Machine.load(raw_machine, ui)
            machine.ui.warn("hello from vagrant")
            SDK::Provider::ActionResp.new(success: true)
          end
        end

        def action_up_spec(req, _unused_call)
          args = [
            Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.TerminalUI",
              name: ""
            ),
            Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Args.Machine",
              name: ""
            ),
          ]
          result = [
            Hashicorp::Vagrant::Sdk::FuncSpec::Value.new(
              type: "hashicorp.vagrant.sdk.Provider.ActionResp",
              name: ""
            ),
          ]
          Hashicorp::Vagrant::Sdk::FuncSpec.new(
            args: args,
            result: result
          )
        end
      end
    end
  end
end
