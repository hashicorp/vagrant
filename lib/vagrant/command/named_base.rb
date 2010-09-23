module Vagrant
  module Command
    # Same as {Base} except adds the `name` argument for you. This superclass
    # is useful if you're creating a command which should be able to target
    # a specific VM in a multi-VM environment. For example, in a multi-VM
    # environment, `vagrant up` "ups" all defined VMs, but you can specify a
    # name such as `vagrant up web` to target only a specific VM. That name
    # argument is from {NamedBase}. Of course, you can always add it manually
    # yourself, as well.
    class NamedBase < Base
      argument :name, :type => :string, :optional => true
    end
  end
end
