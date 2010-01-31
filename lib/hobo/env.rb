require 'yaml'

module Hobo
  class Env
    HOBOFILE_NAME = "hobofile"
    HOME =  File.expand_path('~/.hobo')
    CONFIG = { File.join(HOME, 'config.yml') => '/config/default.yml' }
    ENSURE = {
      :files => CONFIG.merge({}), #additional files go mhia!
      :dirs => [HOME] #additional dirs go mhia!
    }

    # Initialize class variables used
    @@persisted_uuid = nil
    @@root_path = nil

    class << self
      def persisted_uuid; @@persisted_uuid; end
      def root_path; @@root_path; end

      def load!
        load_root_path!
        load_config!
        load_uuid!
      end

      def ensure_directories
        ENSURE[:dirs].each do |name|
          Dir.mkdir(name) unless File.exists?(name)
        end
      end

      def ensure_files
        ENSURE[:files].each do |target, default|
          File.copy(File.join(PROJECT_ROOT, default), target) unless File.exists?(target)
        end
      end

      def load_config!
        ensure_directories
        ensure_files

        HOBO_LOGGER.info "Loading config from #{CONFIG.keys.first}"
        parsed = YAML.load_file(CONFIG.keys.first)
        Hobo.config!(parsed)
      end

      def load_uuid!
        File.open(File.join(root_path, Hobo.config[:dotfile_name])) do |f|
          @@persisted_uuid = f.read
        end
      rescue Errno::ENOENT
        @@persisted_uuid = nil
      end

      def load_root_path!(path=Pathname.new(Dir.pwd))
        if path.to_s == '/'
          error_and_exit(<<-msg)
A `Hobofile` was not found! This file is required for hobo to run
since it describes the expected environment that hobo is supposed
to manage. Please create a Hobofile and place it in your project
root.
msg
          return
        end

        file = "#{path}/#{HOBOFILE_NAME}"
        if File.exist?(file)
          @@root_path = path.to_s
          return
        end

        load_root_path!(path.parent)
      end

      def error_and_exit(error)
        puts <<-error
=====================================================================
Hobo experienced an error!

#{error.chomp}
=====================================================================
error
        exit
      end
    end
  end
end
