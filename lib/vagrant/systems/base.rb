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
      include Vagrant::Util

      # The VM which this system is tied to.
      attr_reader :vm

      # Initializes the system. Any subclasses MUST make sure this
      # method is called on the parent. Therefore, if a subclass overrides
      # `initialize`, then you must call `super`.
      def initialize(vm)
        @vm = vm
      end

      # Mounts a shared folder. This method is called by the shared
      # folder action with an open SSH session (passed in as `ssh`).
      # This method should create, mount, and properly set permissions
      # on the shared folder. This method should also properly
      # adhere to any configuration values such as `shared_folder_uid`
      # on `config.vm`.
      #
      # @param [Object] ssh The Net::SSH session.
      # @param [String] name The name of the shared folder.
      # @param [String] guestpath The path on the machine which the user
      #   wants the folder mounted.
      def mount_shared_folder(ssh, name, guestpath); end
    end
  end
end