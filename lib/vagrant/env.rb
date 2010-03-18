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
        load_config!
        check_virtualbox!
        load_vm!
      end

      def check_virtualbox!
        version = VirtualBox::Command.version
        if version.nil?
          error_and_exit(:virtualbox_not_detected)
        elsif version.to_f < 3.1
          error_and_exit(:virtualbox_invalid_version, :version => version.to_s)
        end

        if !VirtualBox::Global.vboxconfig?
          error_and_exit(:virtualbox_xml_not_detected)
        end
      end

      def load_config!
        # Prepare load paths for config files
        load_paths = [File.join(PROJECT_ROOT, "config", "default.rb")]
        load_paths << File.join(box.directory, ROOTFILE_NAME) if box
        load_paths << File.join(home_path, ROOTFILE_NAME) if Vagrant.config.vagrant.home
        load_paths << File.join(root_path, ROOTFILE_NAME) if root_path

        # Then clear out the old data
        Config.reset!

        load_paths.each do |path|
          if File.exist?(path)
            logger.info "Loading config from #{path}..."
            load path
          end
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
        # Save to the dotfile for this project
        File.open(dotfile_path, 'w+') do |f|
          f.write(vm.uuid)
        end

        # Also add to the global store
        ActiveList.add(vm)
      end

      def depersist_vm(vm)
        # Delete the dotfile if it exists
        File.delete(dotfile_path) if File.exist?(dotfile_path)

        # Remove from the global store
        ActiveList.remove(vm)
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
          error_and_exit(:rootfile_not_found)
        end
      end

      def require_box
        require_root_path

        if !box
          if !Vagrant.config.vm.box
            error_and_exit(:box_not_specified)
          else
            error_and_exit(:box_specified_doesnt_exist, :box_name => Vagrant.config.vm.box)
          end
        end
      end

      def require_persisted_vm
        require_root_path

        if !persisted_vm
          error_and_exit(:environment_not_created)
        end
      end
    end
  end
end
