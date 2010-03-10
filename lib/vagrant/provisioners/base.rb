module Vagrant
  module Provisioners
    # The base class for a "provisioner." A provisioner is responsible for
    # provisioning a Vagrant system. This has been abstracted out to provide
    # support for multiple solutions such as Chef Solo, Chef Client, and
    # Puppet.
    class Base
      include Vagrant::Util

      # This is the single method called to provision the system. This method
      # is expected to do whatever necessary to provision the system (create files,
      # SSH, etc.)
      def provision!; end
    end
  end
end