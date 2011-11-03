require "yaml"

require "log4r"

module Acceptance
  # This represents a configuration object for acceptance tests.
  class Config
    attr_reader :vagrant_path
    attr_reader :vagrant_version
    attr_reader :env

    def initialize(path)
      @logger = Log4r::Logger.new("acceptance::config")
      @logger.info("Loading configuration from: #{path}")
      options = YAML.load_file(path)
      @logger.info("Loaded: #{options.inspect}")

      @vagrant_path    = options["vagrant_path"]
      @vagrant_version = options["vagrant_version"]
      @env             = options["env"]
    end
  end
end
