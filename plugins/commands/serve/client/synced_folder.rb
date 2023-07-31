# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class SyncedFolder < Client
        include CapabilityPlatform
        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def usable_func
          spec = client.usable_spec(Empty.new)
          cb = proc do |args|
            client.usable(args).usable
          end
          [spec, cb]
        end

        # Check if synced folders are usable for guest
        #
        # @param machine [Vagrant::Machine] Guest machine
        # @return [Boolean]
        def usable(machine)
          run_func(machine)
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def prepare_func
          spec = client.prepare_spec(Empty.new)
          cb = proc do |args|
            client.prepare(args)
          end
          [spec, cb]
        end

        # Prepare synced folders on guest
        #
        # @param machine [Vagrant::Machine] Guest machine
        # @param folders [Hash] Synced folders
        # @param opts [Hash] Options for folders
        def prepare(machine, folders, opts)
          run_func(machine,
            Type::Folders.new(value: folders),
            Type::Options.new(value: opts),
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def enable_func
          spec = client.enable_spec(Empty.new)
          cb = proc do |args|
            client.enable(args)
          end
          [spec, cb]
        end

        # Enable synced folders on guest
        #
        # @param machine [Vagrant::Machine] Guest machine
        # @param folders [Hash] Synced folders
        # @param opts [Hash] Options for folders
        def enable(machine, folders, opts)
          run_func(machine,
            Type::Folders.new(value: folders),
            Type::Options.new(value: opts),
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def disable_func
          spec = client.disable_spec(Empty.new)
          cb = proc do |args|
            client.disable(args)
          end
          [spec, cb]
        end

        # Disable synced folders on guest
        #
        # @param machine [Vagrant::Machine] Guest machine
        # @param folders [Hash] Synced folders
        # @param opts [Hash] Options for folders
        def disable(machine, folders, opts)
          run_func(machine,
            Type::Folders.new(value: folders),
            Type::Options.new(value: opts),
          )
        end

        # Generate callback and spec for required arguments
        #
        # @return [SDK::FuncSpec, Proc]
        def cleanup_func
          spec = client.cleanup_spec(Empty.new)
          cb = proc do |args|
            client.cleanup(args)
          end
          [spec, cb]
        end

        # Cleanup synced folders on guest
        #
        # @param machine [Vagrant::Machine] Guest machine
        # @param opts [Hash] Options for folders
        def cleanup(machine, opts)
          run_func(machine, Type::Options.new(value: opts))
        end
      end
    end
  end
end
