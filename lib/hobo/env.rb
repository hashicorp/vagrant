module Hobo
  class Env
    DIRS = [ File.expand_path('~/.hobo') ]
    CONFIG_FILE = { File.expand_path('~/.hobo/config.yml') => '/config/default.yml' }
    FILES = CONFIG_FILE.merge({}) #additional files go mhia!
    
    def ensure_directories
      DIRS.each do |name|
        Dir.mkdir(name) unless File.exists?(name)
      end
    end

    def ensure_files
      FILES.each do |target, default|
        File.copy(PROJECT_ROOT + default, target) unless File.exists?(target)
      end
    end
    
    def load_config
      ensure_directories
      ensure_files
      parsed = yield(CONFIG_FILE.keys.first)
      Config.from_hash!(parsed)
    end
  end
end
