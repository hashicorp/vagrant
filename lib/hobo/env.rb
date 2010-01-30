require 'yaml'

module Hobo
  class Env
    HOME =  File.expand_path('~/.hobo')
    CONFIG = { File.join(HOME, 'config.yml') => '/config/default.yml' }
    ENSURE = { 
      :files => CONFIG.merge({}), #additional files go mhia!
      :dirs => [HOME] #additional dirs go mhia!
    }
    PATH_CHUNK_REGEX = /\/[^\/]+$/

    class << self
      def load!
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
        @@persisted_uuid = load_dotfile
      end

      def load_dotfile(dir=Dir.pwd)
        return nil if dir.empty?

        file = "#{dir}/#{Hobo.config[:dotfile_name]}"
        if File.exists?(file)
          # TODO check multiple lines after the first for information
          return File.open(file, 'r').first
        end
        
        load_dotfile(dir.sub(PATH_CHUNK_REGEX, '')) 
      end

      def persisted_uuid
        @@persisted_uuid
      end
    end
  end
end
