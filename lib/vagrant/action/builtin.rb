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
        use VM::Customize
        use VM::ForwardPorts
        use VM::Provision
        use VM::ShareFolders
        use VM::Network
        use VM::Boot
      end

      register :start, start

      # halt - Halts the VM, attempting gracefully but then forcing
      # a restart if fails.
      halt = Builder.new do
        use VM::Halt
      end

      register :halt, halt

      # reload - Halts then restarts the VM
      reload = Builder.new do
        use Action[:halt]
        use Action[:start]
      end

      register :reload, reload

      # up - Imports, prepares, then starts a fresh VM.
      up = Builder.new do
        use VM::Import
        use VM::Persist
        use VM::MatchMACAddress
        use VM::CheckGuestAdditions
        use Action[:start]
      end

      register :up, up

      # destroy - Halts, cleans up, and destroys an existing VM
      destroy = Builder.new do
        use Action[:halt]
        use VM::DestroyUnusedNetworkInterfaces
        use VM::Destroy
      end

      register :destroy, destroy
    end
  end
end
