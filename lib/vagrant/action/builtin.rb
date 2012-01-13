module Vagrant
  module Action
    # Registers the builtin actions with a specific registry.
    #
    # These are the pre-built action sequences that are shipped with
    # Vagrant itself.
    def self.builtin!(registry)
      # provision - Provisions a running VM
      registry.register(:provision) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::Provision
        end
      end

      # start - Starts a VM, assuming it already exists on the
      # environment.
      registry.register(:start) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::CleanMachineFolder
          use VM::ClearForwardedPorts
          use VM::CheckPortCollisions, :port_collision_handler => :correct
          use VM::ForwardPorts
          use VM::Provision
          use VM::PruneNFSExports
          use VM::NFS
          use VM::ClearSharedFolders
          use VM::ShareFolders
          use VM::HostName
          use VM::ClearNetworkInterfaces
          use VM::Network
          use VM::Customize
          use VM::Boot
        end
      end

      # halt - Halts the VM, attempting gracefully but then forcing
      # a restart if fails.
      registry.register(:halt) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::DiscardState
          use VM::Halt
        end
      end

      # suspend - Suspends the VM
      registry.register(:suspend) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::Suspend
        end
      end

      # resume - Resume a VM
      registry.register(:resume) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::CheckPortCollisions
          use VM::Resume
        end
      end

      # reload - Halts then restarts the VM
      registry.register(:reload) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use registry.get(:halt)
          use registry.get(:start)
        end
      end

      # up - Imports, prepares, then starts a fresh VM.
      registry.register(:up) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use VM::CheckBox
          use VM::Import
          use VM::CheckGuestAdditions
          use VM::MatchMACAddress
          use registry.get(:start)
        end
      end

      # destroy - Halts, cleans up, and destroys an existing VM
      registry.register(:destroy) do
        Builder.new do
          use General::Validate
          use VM::CheckAccessible
          use registry.get(:halt), :force => true
          use VM::ProvisionerCleanup
          use VM::PruneNFSExports
          use VM::Destroy
          use VM::CleanMachineFolder
          use VM::DestroyUnusedNetworkInterfaces
        end
      end

      # package - Export and package the VM
      registry.register(:package) do
        Builder.new do
          use General::Validate
          use VM::SetupPackageFiles
          use VM::CheckAccessible
          use registry.get(:halt)
          use VM::ClearForwardedPorts
          use VM::ClearSharedFolders
          use VM::Export
          use VM::PackageVagrantfile
          use VM::Package
        end
      end

      # box_add - Download and add a box.
      registry.register(:box_add) do
        Builder.new do
          use Box::Download
          use Box::Unpackage
          use Box::Verify
        end
      end

      # box_remove - Removes/deletes a box.
      registry.register(:box_remove) do
        Builder.new do
          use Box::Destroy
        end
      end

      # box_repackage - Repackages a box.
      registry.register(:box_repackage) do
        Builder.new do
          use Box::Package
        end
      end
    end
  end
end
