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

    def destroy
      execute!(Actions::Stop) if @vm.running?

      logger.info "Destroying VM and associated drives..."
      @vm.destroy(:destroy_image => true)
    end

    def saved?
      @vm.saved?
    end

    def save_state
      logger.info "Saving VM state..."
      @vm.save_state(true)
    end

    def powered_off?; @vm.powered_off? end

    def export(filename); @vm.export(filename, {}, true) end

    def storage_controllers; @vm.storage_controllers end
  end
end
