require "tempfile"

require_relative "shared_helpers"
require_relative "version"

module Vagrant
  # This class manages Vagrant's interaction with Bundler. Vagrant uses
  # Bundler as a way to properly resolve all dependencies of Vagrant and
  # all Vagrant-installed plugins.
  class Bundler
    def self.instance
      @bundler ||= self.new
    end

    # Initializes Bundler and the various gem paths so that we can begin
    # loading gems. This must only be called once.
    def init!(plugins)
      raise "Bundler already initialized" if defined?(::Bundler)

      # Setup the Bundler configuration
      @configfile = Tempfile.new("vagrant-bundler-config")
      @configfile.close

      # Build up the Gemfile for our Bundler context. We make sure to
      # lock Vagrant to our current Vagrant version. In addition to that,
      # we add all our plugin dependencies.
      @gemfile = Tempfile.new("vagrant-gemfile")
      @gemfile.puts(%Q[gem "vagrant", "= #{Vagrant::VERSION}"])
      plugins.each do |plugin|
        @gemfile.puts(%Q[gem "#{plugin}"])
      end
      @gemfile.close

      # Set the environmental variables for Bundler
      ENV["BUNDLE_CONFIG"]  = @configfile.path
      ENV["BUNDLE_GEMFILE"] = @gemfile.path
      ENV["GEM_PATH"] =
        "#{Vagrant.user_data_path.join("gems")}#{::File::PATH_SEPARATOR}#{ENV["GEM_PATH"]}"
      Gem.clear_paths

      # Load Bundler and setup our paths
      require "bundler"
      ::Bundler.setup
    end
  end
end
