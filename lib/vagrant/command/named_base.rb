module Vagrant
  module Command
    # Same as {Base} except adds the `name` argument so that you
    # can use methods such as `target_vms` in your command.
    class NamedBase < Base
      argument :name, :type => :string, :optional => true
    end
  end
end
