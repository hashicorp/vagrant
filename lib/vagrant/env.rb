module Vagrant
  class Env
    ROOTFILE_NAME = "Vagrantfile"
    HOME_SUBDIRS = ["tmp", "boxes"]

    # Initialize class variables used
    @@persisted_vm = nil
    @@root_path = nil
    @@box = nil

    extend Vagrant::Util

    class << self
      def box; @@box; end
      def persisted_vm; @@persisted_vm; end
      def root_path; @@root_path; end
      def dotfile_path;File.join(root_path, Vagrant.config.vagrant.dotfile_name); end
      def home_path; File.expand_path(Vagrant.config.vagrant.home); end
      def tmp_path; File.join(home_path, "tmp"); end
      def boxes_path; File.join(home_path, "boxes"); end

      def load!
        load_root_path!
        load_config!
        load_home_directory!
        load_box!
        check_virtualbox!
        load_vm!
      end

      def check_virtualbox!
        version = VirtualBox::Command.version
        if version.nil?
          error_and_exit(<<-msg)
Vagrant could not detect VirtualBox! Make sure VirtualBox is properly installed.
If VirtualBox is installed, you may need to tweak the paths to the `VBoxManage`
application which ships with VirtualBox and the path to the global XML configuration
which VirtualBox typically stores somewhere in your home directory.

The following shows how to configure VirtualBox. This can be done in the
Vagrantfile. Note that 90% of the time, you shouldn't need to do this if VirtualBox
is installed. Please use the various Vagrant support lines to request more information
if you can't get this working.

VirtualBox::Command.vboxmanage = "/path/to/my/VBoxManage"
VirtualBox::Global.vboxconfig = "~/path/to/VirtualBox.xml"
msg
        elsif version.to_f < 3.0
          error_and_exit(<<-msg)
Vagrant has detected that you have VirtualBox version #{version} installed!
Vagrant requires that you use at least VirtualBox version 3. Please install
a more recent version of VirtualBox to continue.
msg
        end
      end

      def load_config!
        # Prepare load paths for config files
        load_paths = [File.join(PROJECT_ROOT, "config", "default.rb")]
        load_paths << File.join(box.directory, ROOTFILE_NAME) if box
        load_paths << File.join(root_path, ROOTFILE_NAME) if root_path

        # Then clear out the old data
        Config.reset!

        load_paths.each do |path|
          logger.info "Loading config from #{path}..."
          load path if File.exist?(path)
        end

        # Execute the configurations
        Config.execute!
      end

      def load_home_directory!
        home_dir = File.expand_path(Vagrant.config.vagrant.home)

        dirs = HOME_SUBDIRS.collect { |path| File.join(home_dir, path) }
        dirs.unshift(home_dir)

        dirs.each do |dir|
          next if File.directory?(dir)

          logger.info "Creating home directory since it doesn't exist: #{dir}"
          FileUtils.mkdir_p(dir)
        end
      end

      def load_box!
        return unless root_path

        @@box = Box.find(Vagrant.config.vm.box) if Vagrant.config.vm.box

        if @@box
          logger.info("Reloading configuration to account for loaded box...")
          load_config!
        end
      end

      def load_vm!
        return if !root_path || !File.file?(dotfile_path)

        File.open(dotfile_path) do |f|
          @@persisted_vm = Vagrant::VM.find(f.read)
        end
      rescue Errno::ENOENT
        @@persisted_vm = nil
      end

      def persist_vm(vm)
        File.open(dotfile_path, 'w+') do |f|
          f.write(vm.uuid)
        end
      end

      def load_root_path!(path=nil)
        path = Pathname.new(File.expand_path(path || Dir.pwd))

        # Stop if we're at the root.
        return false if path.root?

        file = "#{path}/#{ROOTFILE_NAME}"
        if File.exist?(file)
          @@root_path = path.to_s
          return true
        end

        load_root_path!(path.parent)
      end

      def require_root_path
        if !root_path
          error_and_exit(<<-msg)
A `#{ROOTFILE_NAME}` was not found! This file is required for vagrant to run
since it describes the expected environment that vagrant is supposed
to manage. Please create a #{ROOTFILE_NAME} and place it in your project
root.
msg
        end
      end

      def require_box
        require_root_path

        if !box
          if !Vagrant.config.vm.box
            error_and_exit(<<-msg)
No base box was specified! A base box is required as a staring point
for every vagrant virtual machine. Please specify one in your Vagrantfile
using `config.vm.box`
msg
          else
            error_and_exit(<<-msg)
Specified box `#{Vagrant.config.vm.box}` does not exist!

The box must be added through the `vagrant box add` command. Please view
the documentation associated with the command for more information.
msg
          end
        end
      end

      def require_persisted_vm
        require_root_path

        if !persisted_vm
          error_and_exit(<<-error)
The task you're trying to run requires that the vagrant environment
already be created, but unfortunately this vagrant still appears to
have no box! You can setup the environment by setting up your
#{ROOTFILE_NAME} and running `vagrant up`
error
          return
        end
      end
    end
  end
end
