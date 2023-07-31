# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Provider < Client
        include CapabilityPlatform

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def usable_func
          spec = client.usable_spec(Empty.new)
          cb = proc do |args|
            client.usable(args).is_usable
          end
          [spec, cb]
        end

        # @return [Boolean] is the provider usable
        def usable?
          run_func
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def installed_func
          spec = client.installed_spec(Empty.new)
          cb = proc do |args|
            client.installed(args).is_installed
          end
          [spec, cb]
        end

        # @return [Boolean] is the provider installed
        def installed?
          run_func
        end

        # Generate callback and spec for required arguments
        #
        # @param name [String, Symbol] name of action
        # @return [SDK::FuncSpec, Proc]
        def action_func(name)
          name = name.to_s
          spec = client.action_spec(
            SDK::Provider::ActionRequest.new(
              name: name
            )
          )
          cb = proc do |args|
            client.action(
              SDK::Provider::ActionRequest.new(
                name: name,
                func_args: args,
              )
            )
          end
          [spec, cb]
        end

        # @param [Sdk::Args::Machine]
        # @param [Symbol] name of the action to run
        def action(machine, name)
          proc do |opts|
            opts = {} if !opts.is_a?(Hash)
            opts.compact!
            # TODO: These entries are deleted because they
            # cannot be mapped. This needs to be revisited
            # after more of core has been ported.
            opts.delete(:action_runner)
            opts.delete(:box_collection)
            opts.delete(:hook)
            opts.delete(:triggers)
            run_func(
              machine,
              Type::Options.new(value: opts),
              func_args: name,
              name: :action_func,
            )
          end
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def machine_id_changed_func
          spec = client.machine_id_changed_spec(Empty.new)
          cb = proc do |args|
            client.machine_id_changed(args)
          end
          [spec, cb]
        end

        # @param [Sdk::Args::Machine]
        def machine_id_changed(machine)
          run_func(machine)
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def ssh_info_func
          spec = client.ssh_info_spec(Empty.new)
          cb = proc do |args|
            Vagrant::Util::HashWithIndifferentAccess.new(
              _cleaned_ssh_info_hash(client.ssh_info(args))
            )
          end
          [spec, cb]
        end

        # @param [Sdk::Args::Machine]
        # @return [Hash] ssh info for machine
        def ssh_info(machine)
          run_func(machine)
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def state_func
          spec = client.state_spec(Empty.new)
          cb = proc do |args|
            mapper.map(client.state(args), to: Vagrant::MachineState)
          end
          [spec, cb]
        end

        # @param [Sdk::Args::Machine]
        # @return [Vagrant::MachineState] machine state
        def state(machine)
          run_func(machine)
        end

        private

        # Machine#ssh_info populates defaults only when it sees nil values, but
        # protobufs send back typed zero values instead (e.g. "" for string, 0 for int,
        # etc.). So in order to get the caller to properly populate defaults,
        # we need to clean up the hash before we return it
        def _cleaned_ssh_info_hash(ssh_info)
          info_hash = ssh_info.to_h
          info_hash.delete_if do |k, v|
            hazzer = :"has_#{k}?"
            ssh_info.respond_to?(hazzer) && !ssh_info.send(hazzer)
          end
          info_hash
        end
      end
    end
  end
end
