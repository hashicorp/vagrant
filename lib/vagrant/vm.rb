module Vagrant
  class VM
    include Vagrant::Util

    attr_accessor :vm
    attr_reader :actions
    attr_accessor :from

    class << self
      # Executes a specific action
      def execute!(action_klass)
        vm = new
        vm.add_action(action_klass)
        vm.execute!
      end

      # Unpack the specified vm package
      def unpackage(package_path)
        working_dir = package_path.chomp(File.extname(package_path))
        new_base_dir = File.join(Vagrant.config[:vagrant][:home], File.basename(package_path, '.*'))

        # Exit if folder of same name exists
        # TODO provide a way for them to specify the directory name
        error_and_exit(<<-error) if File.exists?(new_base_dir)
The directory `#{File.basename(package_path, '.*')}` already exists under #{Vagrant.config[:vagrant][:home]}. Please
remove it, rename your packaged VM file, or (TODO) specifiy an
alternate directory
error

        logger.info "Creating working dir: #{working_dir} ..."
        FileUtils.mkpath(working_dir)

        logger.info "Decompressing the packaged VM: #{package_path} ..."
        decompress(package_path, working_dir)

        logger.info "Moving the unpackaged VM to #{new_base_dir} ..."
        FileUtils.mv(working_dir, Vagrant.config[:vagrant][:home])

        #Return the ovf file for importation
        Dir["#{new_base_dir}/*.ovf"].first
      end

      def decompress(path, dir, file_delimeter=Vagrant.config[:package][:delimiter_regex])
        file = nil
        Zlib::GzipReader.open(path) do |gz|
          begin
            gz.each_line do |line|

              # If the line is a file delimiter create new file and write to it
              if line =~ file_delimeter

                #Write the the part of the line belonging to the previous file
                if file
                  file.write $1
                  file.close
                end

                #Open a new file with the name contained in the delimiter
                file = File.open(File.join(dir, $2), 'w')

                #Write the rest of the line to the new file
                file.write $3
              else
                file.write line
              end
            end
          ensure
            file.close if file
          end
        end
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

    def destroy
      if @vm.running?
        logger.info "VM is running. Forcing immediate shutdown..."
        @vm.stop(true)
      end

      logger.info "Destroying VM and associated drives..."
      @vm.destroy(:destroy_image => true)
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
      delimiter = Vagrant.config[:package][:delimiter]
      folder = FileUtils.mkpath(File.join(to, name))
      logger.info "Creating working directory: #{folder} ..."

      ovf_path = File.join(folder, "#{name}.ovf")
      tar_path = "#{folder}.box"

      logger.info "Exporting required VM files to working directory ..."
      @vm.export(ovf_path)

      logger.info "Packaging VM into #{tar_path} ..."
      Zlib::GzipWriter.open(tar_path) do |gz|
        first_file = true
        Dir.new(folder).each do  |file|
          next if File.directory?(file)
          # Delimit the files, and guarantee new line for next file if not the first
          gz.write "#{delimiter}#{file}#{delimiter}"
          File.open(File.join(folder, file)).each { |line| gz.write(line) }
          first_file = false
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
