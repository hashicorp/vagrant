module Vagrant
  # Represents a single Vagrant environment. This class is responsible
  # for loading all of the Vagrantfile's for the given environment and
  # storing references to the various instances.
  class Environment
    ROOTFILE_NAME = "Vagrantfile"

    include Util

    attr_reader :root_path
    attr_reader :config

    # Loads this environment's configuration and stores it in the {config}
    # variable. The configuration loaded by this method is specified to
    # this environment, meaning that it will use the given root directory
    # to load the Vagrantfile into that context.
    def load_config!
      # Prepare load paths for config files
      load_paths = [File.join(PROJECT_ROOT, "config", "default.rb")]
      load_paths << File.join(root_path, ROOTFILE_NAME) if root_path

      # Clear out the old data
      Config.reset!

      # Load each of the config files in order
      load_paths.each do |path|
        if File.exist?(path)
          logger.info "Loading config from #{path}..."
          load path
        end
      end

      # Execute the configuration stack and store the result
      @config = Config.execute!
    end
  end
end