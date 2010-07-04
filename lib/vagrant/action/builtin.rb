module Vagrant
  class Action
    # Registers the builtin actions. These are locked away in a
    # method so that their definition can be deferred until after
    # all the necessary Vagrant libraries are loaded. Hopefully
    # in the future this will no longer be necessary with autoloading.
    def self.builtin!
      up = Builder.new do
        use VM::Import
        use VM::Customize
        use VM::ForwardPorts
      end

      register :up, up
    end
  end
end
