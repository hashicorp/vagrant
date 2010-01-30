require 'yaml'

module Hobo
  class Env
    HOME =  File.expand_path('~/.hobo')
    CONFIG = { File.join(HOME, 'config.yml') => '/config/default.yml' }
    ENSURE = { 
      :files => CONFIG.merge({}), #additional files go mhia!
      :dirs => [HOME] #additional dirs go mhia!
    }

    class << self
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
      
      def load_config
        ensure_directories
        ensure_files
        
        HOBO_LOGGER.info "Loading config from #{CONFIG.keys.first}"
        parsed = YAML.load_file(CONFIG.keys.first)
        Hobo.config!(parsed)
      end
    end
  end
end
