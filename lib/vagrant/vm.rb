module Vagrant
  class VM < Actions::Runner
    include Vagrant::Util

    attr_reader :env
    attr_reader :system
    attr_accessor :vm

    class << self
      # Finds a virtual machine by a given UUID and either returns
      # a Vagrant::VM object or returns nil.
      def find(uuid, env=nil)
        vm = VirtualBox::VM.find(uuid)
        return nil if vm.nil?
        new(env, vm)
      end
    end

    def initialize(env, vm=nil)
      @env = env
      @vm = vm

      load_system!
    end

    def load_system!
      system = env.config.vm.system

      if system.is_a?(Class)
        @system = system.new(self)
        error_and_exit(:system_invalid_class, :system => system.to_s) unless @system.is_a?(Systems::Base)
      elsif system.is_a?(Symbol)
        # Hard-coded internal systems
        mapping = {
          :linux    => Systems::Linux
        }

        if !mapping.has_key?(system)
          error_and_exit(:system_unknown_type, :system => system.to_s)
          return # for tests
        end

        @system = mapping[system].new(self)
      else
        error_and_exit(:system_unspecified)
      end
    end

    def uuid
      vm ? vm.uuid : nil
    end

    def reload!
      @vm = VirtualBox::VM.find(@vm.uuid)
    end

    def package(out_path, include_files=[])
      add_action(Actions::VM::Export)
      add_action(Actions::VM::Package, out_path, include_files)
      execute!
    end

    def start
      return if @vm.running?

      execute!(Actions::VM::Start)
    end

    def destroy
      execute!(Actions::VM::Down)
    end

    def suspend
      execute!(Actions::VM::Suspend)
    end

    def resume
      execute!(Actions::VM::Resume)
    end

    def saved?
      @vm.saved?
    end

    def powered_off?; @vm.powered_off? end
  end
end
