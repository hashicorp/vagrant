require 'log4r'

module Vagrant
  class VM
    include Vagrant::Util

    attr_reader :env
    attr_reader :name
    attr_reader :vm
    attr_reader :box
    attr_reader :config

    def initialize(name, env, config, vm=nil)
      @logger = Log4r::Logger.new("vagrant::vm")

      @name   = name
      @vm     = vm
      @env    = env
      @config = config
      @box    = env.boxes.find(config.vm.box)

      # Load the associated system.
      load_system!

      @loaded_system_distro = false
    end

    # Loads the system associated with the VM. The system class is
    # responsible for OS-specific functionality. More information
    # can be found by reading the documentation on {Vagrant::Systems::Base}.
    #
    # **This method should never be called manually.**
    def load_system!(system=nil)
      system ||= config.vm.system
      @logger.info("Loading system: #{system}")

      if system.is_a?(Class)
        raise Errors::VMSystemError, :_key => :invalid_class, :system => system.to_s if !(system <= Systems::Base)
        @system = system.new(self)
      elsif system.is_a?(Symbol)
        system_klass = Vagrant.guests.get(system)
        raise Errors::VMSystemError, :_key => :unknown_type, :system => system.to_s if !system_klass
        @system = system_klass.new(self)
      else
        raise Errors::VMSystemError, :unspecified
      end
    end

    # Returns the system for this VM, loading the distro of the system if
    # we can.
    def system
      if !@loaded_system_distro && created? && vm.running?
        # Load the system distro for the first time
        result = @system.distro_dispatch
        load_system!(result)
        @loaded_system_distro = true
      end

      @system
    end

    # Access the {Vagrant::SSH} object associated with this VM.
    # On the initial call, this will initialize the object. On
    # subsequent calls it will reuse the existing object.
    def ssh
      @ssh ||= SSH.new(self)
    end

    # Returns a boolean true if the VM has been created, otherwise
    # returns false.
    #
    # @return [Boolean]
    def created?
      !vm.nil?
    end

    # Sets the currently active VM for this VM. If the VM is a valid,
    # created virtual machine, then it will also update the local data
    # to persist the VM. Otherwise, it will remove itself from the
    # local data (if it exists).
    def vm=(value)
      @vm = value
      env.local_data[:active] ||= {}

      if value && value.uuid
        env.local_data[:active][name.to_s] = value.uuid
      else
        env.local_data[:active].delete(name.to_s)
      end

      # Commit the local data so that the next time vagrant is initialized,
      # it realizes the VM exists
      env.local_data.commit
    end

    def uuid
      vm ? vm.uuid : nil
    end

    def reload!
      @vm = VirtualBox::VM.find(@vm.uuid)
    end

    def package(options=nil)
      run_action(:package, { "validate" => false }.merge(options || {}))
    end

    def up(options=nil)
      run_action(:up, options)
    end

    def start(options=nil)
      raise Errors::VMInaccessible if !@vm.accessible?
      return if @vm.running?
      return resume if @vm.saved?

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

    def saved?
      @vm.saved?
    end

    def powered_off?; @vm.powered_off? end

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
