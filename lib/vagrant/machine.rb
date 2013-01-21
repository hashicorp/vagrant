require "log4r"

module Vagrant
  # This represents a machine that Vagrant manages. This provides a singular
  # API for querying the state and making state changes to the machine, which
  # is backed by any sort of provider (VirtualBox, VMWare, etc.).
  class Machine
    # The box that is backing this machine.
    #
    # @return [Box]
    attr_reader :box

    # Configuration for the machine.
    #
    # @return [Object]
    attr_reader :config

    # Directory where machine-specific data can be stored.
    #
    # @return [Pathname]
    attr_reader :data_dir

    # The environment that this machine is a part of.
    #
    # @return [Environment]
    attr_reader :env

    # ID of the machine. This ID comes from the provider and is not
    # guaranteed to be of any particular format except that it is
    # a string.
    #
    # @return [String]
    attr_reader :id

    # Name of the machine. This is assigned by the Vagrantfile.
    #
    # @return [String]
    attr_reader :name

    # The provider backing this machine.
    #
    # @return [Object]
    attr_reader :provider

    # The provider-specific configuration for this machine.
    #
    # @return [Object]
    attr_reader :provider_config

    # Initialize a new machine.
    #
    # @param [String] name Name of the virtual machine.
    # @param [Class] provider The provider backing this machine. This is
    #   currently expected to be a V1 `provider` plugin.
    # @param [Object] provider_config The provider-specific configuration for
    #   this machine.
    # @param [Object] config The configuration for this machine.
    # @param [Pathname] data_dir The directory where machine-specific data
    #   can be stored. This directory is ensured to exist.
    # @param [Box] box The box that is backing this virtual machine.
    # @param [Environment] env The environment that this machine is a
    #   part of.
    def initialize(name, provider_cls, provider_config, config, data_dir, box, env, base=false)
      @logger = Log4r::Logger.new("vagrant::machine")
      @logger.info("Initializing machine: #{name}")
      @logger.info("  - Provider: #{provider_cls}")
      @logger.info("  - Box: #{box}")
      @logger.info("  - Data dir: #{data_dir}")

      @box             = box
      @config          = config
      @data_dir        = data_dir
      @env             = env
      @name            = name
      @provider_config = provider_config

      # Read the ID, which is usually in local storage
      @id = nil

      # XXX: This is temporary. This will be removed very soon.
      if base
        @id = name
      else
        # Read the id file from the data directory if it exists as the
        # ID for the pre-existing physical representation of this machine.
        id_file = @data_dir.join("id")
        @id = id_file.read if id_file.file?
      end

      # Initializes the provider last so that it has access to all the
      # state we setup on this machine.
      @provider = provider_cls.new(self)
    end

    # This calls an action on the provider. The provider may or may not
    # actually implement the action.
    #
    # @param [Symbol] name Name of the action to run.
    # @param [Hash] extra_env This data will be passed into the action runner
    #   as extra data set on the environment hash for the middleware
    #   runner.
    def action(name, extra_env=nil)
      @logger.info("Calling action: #{name} on provider #{@provider}")

      # Get the callable from the provider.
      callable = @provider.action(name)

      # If this action doesn't exist on the provider, then an exception
      # must be raised.
      if callable.nil?
        raise Errors::UnimplementedProviderAction,
          :action => name,
          :provider => @provider.to_s
      end

      # Run the action with the action runner on the environment
      env = { :machine => self }.merge(extra_env || {})
      @env.action_runner.run(callable, env)
    end

    # Returns a communication object for executing commands on the remote
    # machine. Note that the _exact_ semantics of this are up to the
    # communication provider itself. Despite this, the semantics are expected
    # to be consistent across operating systems. For example, all linux-based
    # systems should have similar communication (usually a shell). All
    # Windows systems should have similar communication as well. Therefore,
    # prior to communicating with the machine, users of this method are
    # expected to check the guest OS to determine their behavior.
    #
    # This method will _always_ return some valid communication object.
    # The `ready?` API can be used on the object to check if communication
    # is actually ready.
    #
    # @return [Object]
    def communicate
      if !@communicator
        # For now, we always return SSH. In the future, we'll abstract
        # this and allow plugins to define new methods of communication.
        klass = Vagrant.plugin("2").manager.communicators[:ssh]
        @communicator = klass.new(self)
      end

      @communicator
    end

    # Returns a guest implementation for this machine. The guest implementation
    # knows how to do guest-OS specific tasks, such as configuring networks,
    # mounting folders, etc.
    #
    # @return [Object]
    def guest
      raise Errors::MachineGuestNotReady if !communicate.ready?

      # Load the initial guest.
      last_guest = config.vm.guest
      guest      = load_guest(last_guest)

      # Loop and distro dispatch while there are distros.
      while true
        distro = guest.distro_dispatch
        break if !distro

        # This is just some really basic loop detection and avoiding for
        # guest classes. This is just here to help implementers a bit
        # avoid a situation that is fairly easy, since if you subclass
        # a parent which does `distro_dispatch`, you'll end up dispatching
        # forever.
        if distro == last_guest
          @logger.warn("Distro dispatch loop in '#{distro}'. Exiting loop.")
          break
        end

        last_guest = distro
        guest      = load_guest(distro)
      end

      # Return the result
      guest
    end

    # This sets the unique ID associated with this machine. This will
    # persist this ID so that in the future Vagrant will be able to find
    # this machine again. The unique ID must be absolutely unique to the
    # virtual machine, and can be used by providers for finding the
    # actual machine associated with this instance.
    #
    # **WARNING:** Only providers should ever use this method.
    #
    # @param [String] value The ID.
    def id=(value)
      # The file that will store the id if we have one. This allows the
      # ID to persist across Vagrant runs.
      id_file = @data_dir.join("id")

      if value
        # Write the "id" file with the id given.
        id_file.open("w+") do |f|
          f.write(value)
        end
      else
        # Delete the file, since the machine is now destroyed
        id_file.delete
      end

      # Store the ID locally
      @id = value

      # Notify the provider that the ID changed in case it needs to do
      # any accounting from it.
      @provider.machine_id_changed
    end

    # This returns a clean inspect value so that printing the value via
    # a pretty print (`p`) results in a readable value.
    #
    # @return [String]
    def inspect
      "#<#{self.class}: #{@name} (#{@provider.class})>"
    end

    # This returns the SSH info for accessing this machine. This SSH info
    # is queried from the underlying provider. This method returns `nil` if
    # the machine is not ready for SSH communication.
    #
    # The structure of the resulting hash is guaranteed to contain the
    # following structure, although it may return other keys as well
    # not documented here:
    #
    #     {
    #       :host => "1.2.3.4",
    #       :port => "22",
    #       :username => "mitchellh",
    #       :private_key_path => "/path/to/my/key"
    #     }
    #
    # Note that Vagrant makes no guarantee that this info works or is
    # correct. This is simply the data that the provider gives us or that
    # is configured via a Vagrantfile. It is still possible after this
    # point when attempting to connect via SSH to get authentication
    # errors.
    #
    # @return [Hash] SSH information.
    def ssh_info
      # First, ask the provider for their information. If the provider
      # returns nil, then the machine is simply not ready for SSH, and
      # we return nil as well.
      info = @provider.ssh_info
      return nil if info.nil?

      # Delete out the nil entries.
      info.dup.each do |key, value|
        info.delete(key) if value.nil?
      end

      # Next, we default some fields if they weren't given to us by
      # the provider.
      info[:host] = @config.ssh.host if @config.ssh.host
      info[:port] = @config.ssh.port if @config.ssh.port
      info[:username] = @config.ssh.username if @config.ssh.username

      # We also set some fields that are purely controlled by Varant
      info[:forward_agent] = @config.ssh.forward_agent
      info[:forward_x11]   = @config.ssh.forward_x11

      # Set the private key path. If a specific private key is given in
      # the Vagrantfile we set that. Otherwise, we use the default (insecure)
      # private key, but only if the provider didn't give us one.
      info[:private_key_path] = @config.ssh.private_key_path if @config.ssh.private_key_path
      info[:private_key_path] = @env.default_private_key_path if !info[:private_key_path]

      # Return the final compiled SSH info data
      info
    end

    # Returns the state of this machine. The state is queried from the
    # backing provider, so it can be any arbitrary symbol.
    #
    # @return [Symbol]
    def state
      result = @provider.state
      raise Errors::MachineStateInvalid if !result.is_a?(MachineState)
      result
    end

    protected

    # Given a guest name (such as `:windows`), this will load the associated
    # guest implementation and return an instance.
    #
    # @param [Symbol] guest The name of the guest implementation.
    # @return [Object]
    def load_guest(guest)
      @logger.info("Loading guest: #{guest}")

      klass = Vagrant.plugin("2").manager.guests[guest]

      if klass.nil?
        raise Errors::VMGuestError,
          :_key  => :unknown_type,
          :guest => guest.to_s
      end

      return klass.new(self)
    end
  end
end
