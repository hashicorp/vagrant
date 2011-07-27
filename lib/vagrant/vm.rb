module Vagrant
  class VM
    include Vagrant::Util

    attr_reader :env
    attr_reader :name
    attr_reader :vm

    class << self
      # Finds a virtual machine by a given UUID and either returns
      # a Vagrant::VM object or returns nil.
      def find(uuid, env=nil, name=nil)
        vm = VirtualBox::VM.find(uuid)
        new(:vm => vm, :env => env, :name => name)
      end
    end

    def initialize(opts=nil)
      defaults = {
        :vm => nil,
        :env => nil,
        :name => nil
      }

      opts = defaults.merge(opts || {})

      @vm = opts[:vm]
      @name = opts[:name]

      if !opts[:env].nil?
        # We have an environment, so we create a new child environment
        # specifically for this VM. This step will load any custom
        # config and such.
        @env = Vagrant::Environment.new({
          :cwd => opts[:env].cwd,
          :parent => opts[:env],
          :vm => self
        }).load!

        # Load the associated system.
        load_system!
      end

      @loaded_system_distro = false
    end

    # Loads the system associated with the VM. The system class is
    # responsible for OS-specific functionality. More information
    # can be found by reading the documentation on {Vagrant::Systems::Base}.
    #
    # **This method should never be called manually.**
    def load_system!(system=nil)
      system ||= env.config.vm.system
      env.logger.info("vm: #{name}") { "Loading system: #{system}" }

      if system.is_a?(Class)
        raise Errors::VMSystemError, :_key => :invalid_class, :system => system.to_s if !(system <= Systems::Base)
        @system = system.new(self)
      elsif system.is_a?(Symbol)
        # Hard-coded internal systems
        mapping = {
          :debian  => Systems::Debian,
          :ubuntu  => Systems::Ubuntu,
          :freebsd => Systems::FreeBSD,
          :gentoo  => Systems::Gentoo,
          :redhat  => Systems::Redhat,
          :suse    => Systems::Suse,
          :linux   => Systems::Linux,
          :solaris => Systems::Solaris,
          :arch    => Systems::Arch
        }

        raise Errors::VMSystemError, :_key => :unknown_type, :system => system.to_s if !mapping.has_key?(system)
        @system = mapping[system].new(self)
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
      @ssh ||= SSH.new(env)
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
      env.actions.run(:package, { "validate" => false }.merge(options || {}))
    end

    def up(options=nil)
      env.actions.run(:up, options)
    end

    def start(options=nil)
      return if @vm.running?
      return resume if @vm.saved?

      env.actions.run(:start, options)
    end

    def halt(options=nil)
      env.actions.run(:halt, options)
    end

    def reload
      env.actions.run(:reload)
    end

    def provision
      env.actions.run(:provision)
    end

    def destroy
      env.actions.run(:destroy)
    end

    def suspend
      env.actions.run(:suspend)
    end

    def resume
      env.actions.run(:resume)
    end

    def saved?
      @vm.saved?
    end

    def powered_off?; @vm.powered_off? end
  end
end
