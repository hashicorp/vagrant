module Vagrant
  class Env
    ROOTFILE_NAME = "Vagrantfile"

    # Initialize class variables used
    @@persisted_vm = nil
    @@root_path = nil

    extend Vagrant::Util

    class << self
      def persisted_vm; @@persisted_vm; end
      def root_path; @@root_path; end
      def dotfile_path; File.join(root_path, Vagrant.config.dotfile_name); end

      def load!
        load_root_path!
        load_config!
        load_vm!
      end

      def load_config!
        load_paths = [
          File.join(PROJECT_ROOT, "config", "default.rb"),
          File.join(root_path, ROOTFILE_NAME)
        ]

        load_paths.each do |path|
          logger.info "Loading config from #{path}..."
          load path if File.exist?(path)
        end

        # Execute the configurations
        Config.execute!
      end

      def load_vm!
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

      def load_root_path!(path=Pathname.new(Dir.pwd))
        if path.to_s == '/'
          error_and_exit(<<-msg)
A `#{ROOTFILE_NAME}` was not found! This file is required for vagrant to run
since it describes the expected environment that vagrant is supposed
to manage. Please create a #{ROOTFILE_NAME} and place it in your project
root.
msg
          return
        end

        file = "#{path}/#{ROOTFILE_NAME}"
        if File.exist?(file)
          @@root_path = path.to_s
          return
        end

        load_root_path!(path.parent)
      end

      def require_persisted_vm
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
