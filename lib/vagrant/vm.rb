module Vagrant
  class VM
    include Vagrant::Util
    attr_accessor :vm
    attr_reader :actions

    class << self
      # Executes a specific action
      def execute!(action_klass)
        vm = new
        vm.add_action(action_klass)
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

    def add_action(action_klass)
      @actions << action_klass.new(self)
    end

    def execute!
      # Call the prepare method on each once its
      # initialized, then call the execute! method
      [:prepare, :execute!].each do |method|
        @actions.each do |action|
          action.send(method)
        end
      end
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
      if @vm.running?
        logger.info "VM is running. Forcing immediate shutdown..."
        @vm.stop(true)
      end

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

    # TODO the longest method, needs to be split up
    def package(name, to)
      folder = FileUtils.mkpath(File.join(to, name))
      logger.info "Creating working directory: #{folder} ..."

      ovf_path = File.join(folder, "#{name}.ovf")
      tar_path = "#{folder}.box"

      logger.info "Exporting required VM files to working directory ..."
      @vm.export(ovf_path)

      # TODO use zlib ...
      logger.info "Packaging VM into #{name}.box ..."
      Tar.open(tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU) do |tar|
        begin
          # appending the expanded file path adds the whole folder tree
          # to the tar archive there must be a better way
          working_dir = FileUtils.pwd
          FileUtils.cd(to)
          tar.append_tree(name)
        ensure
          FileUtils.cd(working_dir)
        end
      end

      logger.info "Removing working directory ..."
      FileUtils.rm_r(folder)

      tar_path
    end

    def powered_off?; @vm.powered_off? end

    def export(filename); @vm.export(filename, {}, true) end
  end
end
