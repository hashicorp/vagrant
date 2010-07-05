module Vagrant
  class Action
    # Registers the builtin actions. These are locked away in a
    # method so that their definition can be deferred until after
    # all the necessary Vagrant libraries are loaded. Hopefully
    # in the future this will no longer be necessary with autoloading.
    def self.builtin!
      up = Builder.new do
        use VM::Import
        use VM::Persist
        use VM::MatchMACAddress
        use VM::CheckGuestAdditions
        use VM::Customize
        use VM::ForwardPorts
        use VM::Provision
        use VM::ShareFolders
        use VM::Network
        use VM::Boot
      end

      destroy = Builder.new do
        use VM::Halt
        use VM::DestroyUnusedNetworkInterfaces
        use VM::Destroy
      end

      register :up, up
      register :destroy, destroy
    end
  end
end
