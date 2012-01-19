require 'log4r'

module Vagrant
  class VM
    include Vagrant::Util

    attr_reader :uuid
    attr_reader :env
    attr_reader :name
    attr_reader :vm
    attr_reader :box
    attr_reader :config
    attr_reader :driver

    def initialize(name, env, config, opts=nil)
      @logger = Log4r::Logger.new("vagrant::vm")

      @name   = name
      @vm     = nil
      @env    = env
      @config = config
      @box    = env.boxes.find(config.vm.box)

      opts ||= {}
      if opts[:base]
        # The name is the ID we use.
        @uuid = name
      else
        # Load the UUID if its saved.
        active = env.local_data[:active] || {}
        @uuid = active[@name.to_s]
      end

      # Reload ourselves to get the state
      reload!

      # Load the associated guest.
      load_guest!
      @loaded_guest_distro = false
    end

    # Loads the guest associated with the VM. The guest class is
    # responsible for OS-specific functionality. More information
    # can be found by reading the documentation on {Vagrant::Guest::Base}.
    #
    # **This method should never be called manually.**
    def load_guest!(guest=nil)
      guest ||= config.vm.guest
      @logger.info("Loading guest: #{guest}")

      if guest.is_a?(Class)
        raise Errors::VMGuestError, :_key => :invalid_class, :system => guest.to_s if !(guest <= Guest::Base)
        @guest = guest.new(self)
      elsif guest.is_a?(Symbol)
        guest_klass = Vagrant.guests.get(guest)
        raise Errors::VMGuestError, :_key => :unknown_type, :system => guest.to_s if !guest_klass
        @guest = guest_klass.new(self)
      else
        raise Errors::VMGuestError, :unspecified
      end
    end

    # Returns a channel object to communicate with the virtual
    # machine.
    def channel
      @channel ||= Communication::SSH.new(self)
    end

    # Returns the guest for this VM, loading the distro of the system if
    # we can.
    def guest
      if !@loaded_guest_distro && state == :running
        # Load the guest distro for the first time
        result = @guest.distro_dispatch
        load_guest!(result)
        @loaded_guest_distro = true
      end

      @guest
    end

    # Access the {Vagrant::SSH} object associated with this VM, which
    # is used to get SSH credentials with the virtual machine.
    def ssh
      @ssh ||= SSH.new(self)
    end

    # Returns the state of the VM as a symbol.
    #
    # @return [Symbol]
    def state
      return :not_created if !@uuid
      state = @driver.read_state
      return :not_created if !state
      return state
    end

    # Returns a boolean true if the VM has been created, otherwise
    # returns false.
    #
    # @return [Boolean]
    def created?
      state != :not_created
    end

    # Sets the currently active VM for this VM. If the VM is a valid,
    # created virtual machine, then it will also update the local data
    # to persist the VM. Otherwise, it will remove itself from the
    # local data (if it exists).
    def uuid=(value)
      env.local_data[:active] ||= {}
      if value
        env.local_data[:active][name.to_s] = value
      else
        env.local_data[:active].delete(name.to_s)
      end

      # Commit the local data so that the next time vagrant is initialized,
      # it realizes the VM exists
      env.local_data.commit

      # Store the uuid and reload the instance
      @uuid = value
      reload!
    end

    def reload!
      begin
        @driver = Driver::VirtualBox.new(@uuid)
      rescue Driver::VirtualBox::VMNotFound
        # Clear the UUID since this VM doesn't exist. Note that this calls
        # back into `reload!` but shouldn't ever result in infinite
        # recursion since `@uuid` will be nil.
        self.uuid = nil
      end
    end

    def package(options=nil)
      run_action(:package, { "validate" => false }.merge(options || {}))
    end

    def up(options=nil)
      run_action(:up, options)
    end

    def start(options=nil)
      return if state == :running
      return resume if state == :saved

      run_action(:start, options)
    end

    def halt(options=nil)
      run_action(:halt, options)
    end

    def reload
      run_action(:reload)
    end

    def provision
      run_action(:provision)
    end

    def destroy
      run_action(:destroy)
    end

    def suspend
      run_action(:suspend)
    end

    def resume
      run_action(:resume)
    end

    def ui
      return @_ui if defined?(@_ui)
      @_ui = @env.ui.dup
      @_ui.resource = @name
      @_ui
    end

    protected

    def run_action(name, options=nil)
      options = {
        :vm => self,
        :ui => ui
      }.merge(options || {})

      env.action_runner.run(name, options)
    end
  end
end
