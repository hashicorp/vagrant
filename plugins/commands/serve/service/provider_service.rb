require 'vagrant/machine'
require 'vagrant/batch_action'
require 'vagrant/ui'
require 'logger'
require_relative '../client/terminal_client'

module VagrantPlugins
  module CommandServe
    module Service
      class ProviderService < Hashicorp::Vagrant::Sdk::ProviderService::Service
        LOG = Logger.new('/tmp/vagrant-ruby-provider.txt')

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

        def action_up(req, _unused_call)
          LOG.debug("Coming up")
          machine = machine_arg_to_machine(req)
          raw_terminal_arg  = req.args[1].value.value
          ui_client = VagrantPlugins::CommandServe::Client::TerminalClient.terminal_arg_to_terminal_ui(raw_terminal_arg)
          ui = Vagrant::UI::RemoteUI.new(ui_client)
          ui.warn("hello from vagrant")

          # ba = Vagrant::BatchAction.new
          # LOG.debug("registering action")
          # ba.action(machine, :up)
          # LOG.debug("running action")
          # ba.run
          # LOG.debug("up?!")
          Hashicorp::Vagrant::Sdk::Provider::ActionResp.new(success: true)
        end

        def machine_arg_to_machine(req)
          raw_machine_arg = req.args[0].value.value
          machine_arg = Hashicorp::Vagrant::Sdk::Args::Machine.decode(raw_machine_arg)
          LOG.debug("machine id: " + machine_arg.resource_id)
          LOG.debug("server addr: " + machine_arg.serverAddr)

          mclient = Vagrant::MachineClient.new(machine_arg.serverAddr)
          machine = mclient.get_machine(machine_arg.resource_id)
          LOG.debug("got machine: " + machine.name)
          LOG.debug("using provider: " + machine.provider_name)
          machine
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
