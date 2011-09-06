module Vagrant
  class Action
    # Registers the builtin actions. These are locked away in a
    # method so that their definition can be deferred until after
    # all the necessary Vagrant libraries are loaded. Hopefully
    # in the future this will no longer be necessary with autoloading.
    def self.builtin!
      # provision - Provisions a running VM
      register(:provision, Builder.new do
        use VM::Provision
      end)

      # start - Starts a VM, assuming it already exists on the
      # environment.
      register(:start, Builder.new do
        use VM::CleanMachineFolder
        use VM::ClearForwardedPorts
        use VM::ForwardPorts
        use VM::Provision
        use VM::NFS
        use VM::ClearSharedFolders
        use VM::ShareFolders
        use VM::HostName
        use VM::Network
        use VM::Customize
        use VM::Modify
        use VM::Boot
      end)

      # halt - Halts the VM, attempting gracefully but then forcing
      # a restart if fails.
      register(:halt, Builder.new do
        use VM::DiscardState
        use VM::Halt
      end)

      # suspend - Suspends the VM
      register(:suspend, Builder.new do
        use VM::Suspend
      end)

      # resume - Resume a VM
      register(:resume, Builder.new do
        use VM::Resume
      end)

      # reload - Halts then restarts the VM
      register(:reload, Builder.new do
        use Action[:halt]
        use Action[:start]
      end)

      # up - Imports, prepares, then starts a fresh VM.
      register(:up, Builder.new do
        use VM::CheckBox
        use VM::Import
        use VM::MatchMACAddress
        use VM::CheckGuestAdditions
        use Action[:start]
      end)

      # destroy - Halts, cleans up, and destroys an existing VM
      register(:destroy, Builder.new do
        use Action[:halt], :force => true
        use VM::ProvisionerCleanup
        use VM::ClearNFSExports
        use VM::Destroy
        use VM::CleanMachineFolder
        use VM::DestroyUnusedNetworkInterfaces
      end)

      # package - Export and package the VM
      register(:package, Builder.new do
        use Action[:halt]
        use VM::ClearForwardedPorts
        use VM::ClearSharedFolders
        use VM::Modify
        use VM::Export
        use VM::PackageVagrantfile
        use VM::Package
      end)

      # box_add - Download and add a box.
      register(:box_add, Builder.new do
        use Box::Download
        use Box::Unpackage
        use Box::Verify
      end)

      # box_remove - Removes/deletes a box.
      register(:box_remove, Builder.new do
        use Box::Destroy
      end)

      # box_repackage - Repackages a box.
      register(:box_repackage, Builder.new do
        use Box::Package
      end)

      # Other callbacks. There will be more of these in the future. For
      # now, these are limited to what are needed internally.
      register(:before_action_run, Builder.new do
        use General::Validate
        use VM::CheckAccessible
      end)
    end
  end
end
