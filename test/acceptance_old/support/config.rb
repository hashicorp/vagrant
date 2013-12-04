require "yaml"

require "log4r"

module Acceptance
  # This represents a configuration object for acceptance tests.
  class Config
    attr_reader :vagrant_path
    attr_reader :vagrant_version
    attr_reader :env
    attr_reader :box_directory

    def initialize(path)
      @logger = Log4r::Logger.new("test::acceptance::config")
      @logger.info("Loading configuration from: #{path}")
      options = YAML.load_file(path)
      @logger.info("Loaded: #{options.inspect}")

      @vagrant_path    = options["vagrant_path"]
      @vagrant_version = options["vagrant_version"]
      @env             = options["env"]
      @box_directory   = options["box_directory"]

      # Verify the configuration object.
      validate
    end

    # This method verifies the configuration and makes sure that
    # all the configuration is available and appears good. This
    # method will raise an ArgumentError in the case that anything
    # is wrong.
    def validate
      if !@vagrant_path || !File.file?(@vagrant_path)
        raise ArgumentError, "'vagrant_path' must point to the `vagrant` executable"
      elsif !@vagrant_version
        raise ArgumentError, "`vagrant_version' must be set to the version of the `vagrant` executable"
      elsif !@box_directory || !File.directory?(@box_directory)
        raise ArgumentError, "`box_directory` must be set to a folder containing boxes for the tests."
      end
    end
  end
end
