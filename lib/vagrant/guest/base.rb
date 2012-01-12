module Vagrant
  module Guest
    # The base class for a "system." A system represents an installed
    # operating system on a given box. There are some portions of
    # Vagrant which are fairly OS-specific (such as mounting shared
    # folders) and while the number is few, this abstraction allows
    # more obscure operating systems to be installed without having
    # to directly modify Vagrant internals.
    #
    # Subclasses of the system base class are expected to implement
    # all the methods. These methods are described in the comments
    # above their definition.
    #
    # **This is by no means a complete specification. The methods
    # required by systems can and will change at any time. Any
    # changes will be noted on release notes.**
    class Base
      class BaseError < Errors::VagrantError
        error_namespace("vagrant.guest.base")
      end

      include Vagrant::Util

      # The VM which this system is tied to.
      attr_reader :vm

      # Initializes the system. Any subclasses MUST make sure this
      # method is called on the parent. Therefore, if a subclass overrides
      # `initialize`, then you must call `super`.
      def initialize(vm)
        @vm = vm
      end

      # This method is automatically called when the system is available (when
      # Vagrant can successfully SSH into the machine) to give the system a chance
      # to determine the distro and return a distro-specific system.
      #
      # **Warning:** If a return value which subclasses from {Base} is
      # returned, Vagrant will use it as the new system instance for the
      # class.
      def distro_dispatch; end

      # Halt the machine. This method should gracefully shut down the
      # operating system. This method will cause `vagrant halt` and associated
      # commands to _block_, meaning that if the machine doesn't halt
      # in a reasonable amount of time, this method should just return.
      #
      # If when this method returns, the machine's state isn't "powered_off,"
      # Vagrant will proceed to forcefully shut the machine down.
      def halt
        raise BaseError, :_key => :unsupported_halt
      end

      # Mounts a shared folder.
      #
      # This method should create, mount, and properly set permissions
      # on the shared folder. This method should also properly
      # adhere to any configuration values such as `shared_folder_uid`
      # on `config.vm`.
      #
      # @param [String] name The name of the shared folder.
      # @param [String] guestpath The path on the machine which the user
      #   wants the folder mounted.
      # @param [Hash] options Additional options for the shared folder
      #   which can be honored.
      def mount_shared_folder(name, guestpath, options)
        raise BaseError, :_key => :unsupported_shared_folder
      end

      # Mounts a shared folder via NFS. This assumes that the exports
      # via the host are already done.
      def mount_nfs(ip, folders)
        raise BaseError, :_key => :unsupported_nfs
      end

      # Configures the given list of networks on the virtual machine.
      #
      # The networks parameter will be an array of hashes where the hashes
      # represent the configuration of a network interface. The structure
      # of the hash will be roughly the following:
      #
      # {
      #   :type      => :static,
      #   :ip        => "33.33.33.10",
      #   :netmask   => "255.255.255.0",
      #   :interface => 1
      # }
      #
      def configure_networks(networks)
        raise BaseError, :_key => :unsupported_configure_networks
      end

      # Called to change the hostname of the virtual machine.
      def change_host_name(name)
        raise BaseError, :_key => :unsupported_host_name
      end
    end
  end
end
