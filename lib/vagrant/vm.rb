module Vagrant
  class VM
    include Vagrant::Util

    attr_accessor :vm
    attr_reader :actions
    attr_accessor :from

    class << self
      # Executes a specific action
      def execute!(action_klass, *args)
        vm = new
        vm.add_action(action_klass, *args)
        vm.execute!
      end

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
      @actions = []
    end

    def add_action(action_klass, *args)
      @actions << action_klass.new(self, *args)
    end

    def execute!(single_action=nil, *args)
      if single_action
        @actions.clear
        add_action(single_action, *args)
      end

      # Call the prepare method on each once its
      # initialized, then call the execute! method
      return_value = nil
      [:prepare, :execute!].each do |method|
        @actions.each do |action|
          return_value = action.send(method)
        end
      end
      return_value
    end

    # Invokes an "around callback" which invokes before_name and
    # after_name for the given callback name, yielding a block between
    # callback invokations.
    def invoke_around_callback(name, *args)
      invoke_callback("before_#{name}".to_sym, *args)
      yield
      invoke_callback("after_#{name}".to_sym, *args)
    end

    def invoke_callback(name, *args)
      # Attempt to call the method for the callback on each of the
      # actions
      results = []
      @actions.each do |action|
        results << action.send(name, *args) if action.respond_to?(name)
      end
      results
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
