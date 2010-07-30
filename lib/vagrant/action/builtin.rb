module Vagrant
  class Action
    # Registers the builtin actions. These are locked away in a
    # method so that their definition can be deferred until after
    # all the necessary Vagrant libraries are loaded. Hopefully
    # in the future this will no longer be necessary with autoloading.
    def self.builtin!
      # provision - Provisions a running VM
      provision = Builder.new do
        use VM::Provision
      end

      register :provision, provision

      # start - Starts a VM, assuming it already exists on the
      # environment.
      start = Builder.new do
        use VM::CleanMachineFolder
        use VM::Customize
        use VM::ClearForwardedPorts
        use VM::ForwardPorts
        use VM::Provision
        use VM::NFS
        use VM::ClearSharedFolders
        use VM::ShareFolders
        use VM::Network
        use VM::Boot
      end

      register :start, start

      # halt - Halts the VM, attempting gracefully but then forcing
      # a restart if fails.
      halt = Builder.new do
        use VM::DiscardState
        use VM::Halt
        use VM::DisableNetworks
      end

      register :halt, halt

      # suspend - Suspends the VM
      suspend = Builder.new do
        use VM::Suspend
      end

      register :suspend, suspend

      # resume - Resume a VM
      resume = Builder.new do
        use VM::Resume
      end

      register :resume, resume

      # reload - Halts then restarts the VM
      reload = Builder.new do
        use Action[:halt]
        use Action[:start]
      end

      register :reload, reload

      # up - Imports, prepares, then starts a fresh VM.
      up = Builder.new do
        use VM::CheckBox
        use VM::Import
        use VM::Persist
        use VM::MatchMACAddress
        use VM::CheckGuestAdditions
        use Action[:start]
      end

      register :up, up

      # destroy - Halts, cleans up, and destroys an existing VM
      destroy = Builder.new do
        use Action[:halt], :force => true
        use VM::ClearNFSExports
        use VM::DestroyUnusedNetworkInterfaces
        use VM::Destroy
        use VM::CleanMachineFolder
      end

      register :destroy, destroy

      # package - Export and package the VM
      package = Builder.new do
        use Action[:halt]
        use VM::ClearForwardedPorts
        use VM::ClearSharedFolders
        use VM::Export
        use VM::PackageVagrantfile
        use VM::Package
      end

      register :package, package

      # box_add - Download and add a box.
      box_add = Builder.new do
        use Box::Download
        use Box::Unpackage
        use Box::Verify
      end

      register :box_add, box_add

      # box_remove - Removes/deletes a box.
      box_remove = Builder.new do
        use Box::Destroy
      end

      register :box_remove, box_remove

      # box_repackage - Repackages a box.
      box_repackage = Builder.new do
        use Box::Package
      end

      register :box_repackage, box_repackage
    end
  end
end
