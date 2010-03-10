module Vagrant
  class VM < Actions::Runner
    include Vagrant::Util

    attr_accessor :vm
    attr_accessor :from

    class << self
      # Finds a virtual machine by a given UUID and either returns
      # a Vagrant::VM object or returns nil.
      def find(uuid)
        vm = VirtualBox::VM.find(uuid)
        return nil if vm.nil?
        new(vm)
      end
    end

    def initialize(vm=nil)
      @vm = vm
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
