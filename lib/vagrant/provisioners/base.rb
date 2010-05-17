module Vagrant
  module Provisioners
    # The base class for a "provisioner." A provisioner is responsible for
    # provisioning a Vagrant system. This has been abstracted out to provide
    # support for multiple solutions such as Chef Solo, Chef Client, and
    # Puppet.
    class Base
      include Vagrant::Util

      # The VM which this is being provisioned for
      attr_reader :vm

      def initialize(vm)
        @vm = vm
      end

      # This method returns the environment which the provisioner is working
      # on. This is also the environment of the VM. This method is provided
      # as a simple helper since the environment is often used throughout the
      # provisioner.
      def env
        @vm.env
      end

      # This is the method called to "prepare" the provisioner. This is called
      # before any actions are run by the action runner (see {Vagrant::Actions::Runner}).
      # This can be used to setup shared folders, forward ports, etc. Whatever is
      # necessary on a "meta" level.
      def prepare; end

      # This is the method called to provision the system. This method
      # is expected to do whatever necessary to provision the system (create files,
      # SSH, etc.)
      def provision!; end
    end
  end
end