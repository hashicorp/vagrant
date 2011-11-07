module Vagrant
  module Systems
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
        error_namespace("vagrant.systems.base")
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
      def halt; end

      # Mounts a shared folder. This method is called by the shared
      # folder action with an open SSH session (passed in as `ssh`).
      # This method should create, mount, and properly set permissions
      # on the shared folder. This method should also properly
      # adhere to any configuration values such as `shared_folder_uid`
      # on `config.vm`.
      #
      # @param [Object] ssh session.
      # @param [String] name The name of the shared folder.
      # @param [String] guestpath The path on the machine which the user
      #   wants the folder mounted.
      def mount_shared_folder(ssh, name, guestpath, owner, group); end

      # Mounts a shared folder via NFS. This assumes that the exports
      # via the host are already done.
      def mount_nfs(ip, folders); end

      # Prepares the system for host only networks. This is called
      # once prior to any `enable_host_only_network` calls.
      def prepare_host_only_network(net_options=nil)
        raise BaseError, :_key => :unsupported_host_only
      end

      # Setup the system by adding a new host only network. This
      # method should configure and bring up the interface for the
      # given options.
      #
      # @param [Hash] net_options The options for the network.
      def enable_host_only_network(net_options); end

      def change_host_name(name)
        raise BaseError, :_key => :unsupported_host_name
      end
    end
  end
end
