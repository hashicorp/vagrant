require "pathname"
require "tempfile"

require "bundler"

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

    def initialize
      @gem_home = ENV["GEM_HOME"]
      @gem_path = ENV["GEM_PATH"]

      # Set the Bundler UI to be a silent UI. We have to add the
      # `silence` method to it because Bundler UI doesn't have it.
      ::Bundler.ui = ::Bundler::UI.new
      if !::Bundler.ui.respond_to?(:silence)
        ui = ::Bundler.ui
        def ui.silence(*args)
          yield
        end
      end
    end

    # Initializes Bundler and the various gem paths so that we can begin
    # loading gems. This must only be called once.
    def init!(plugins)
      # Setup the Bundler configuration
      @configfile = File.open(Tempfile.new("vagrant").path + "1", "w+")
      @configfile.close

      # Build up the Gemfile for our Bundler context. We make sure to
      # lock Vagrant to our current Vagrant version. In addition to that,
      # we add all our plugin dependencies.
      @gemfile = build_gemfile(plugins)

      # Set the environmental variables for Bundler
      ENV["BUNDLE_CONFIG"]  = @configfile.path
      ENV["BUNDLE_GEMFILE"] = @gemfile.path
      ENV["GEM_PATH"] =
        "#{Vagrant.user_data_path.join("gems")}#{::File::PATH_SEPARATOR}#{@gem_path}"
      Gem.clear_paths
    end

    # Installs the list of plugins.
    #
    # @return [Array<Gem::Specification>]
    def install(plugins)
      gemfile    = build_gemfile(plugins)
      lockfile   = "#{gemfile.path}.lock"
      definition = ::Bundler::Definition.build(gemfile, lockfile, nil)
      root       = File.dirname(gemfile.path)
      opts       = {}
      opts["update"] = true

      with_isolated_gem do
        ::Bundler::Installer.install(root, definition, opts)
      end

      # TODO(mitchellh): clean gems here... for some reason when I put
      # it in on install, we get a GemNotFound exception. Gotta investigate.

      definition.specs
    rescue ::Bundler::VersionConflict => e
      raise Errors::PluginInstallVersionConflict,
        conflicts: e.to_s.gsub("Bundler", "Vagrant")
    end

    # Clean removes any unused gems.
    def clean(plugins)
      gemfile    = build_gemfile(plugins)
      lockfile   = "#{gemfile.path}.lock"
      definition = ::Bundler::Definition.build(gemfile, lockfile, nil)
      root       = File.dirname(gemfile.path)

      with_isolated_gem do
        runtime = ::Bundler::Runtime.new(root, definition)
        runtime.clean
      end
    end

    # Builds a valid Gemfile for use with Bundler given the list of
    # plugins.
    #
    # @return [Tempfile]
    def build_gemfile(plugins)
      f = File.open(Tempfile.new("vagrant").path + "2", "w+")
      f.tap do |gemfile|
        gemfile.puts(%Q[source "https://rubygems.org"])
        gemfile.puts(%Q[source "http://gems.hashicorp.com"])
        gemfile.puts(%Q[gem "vagrant", "= #{Vagrant::VERSION}"])
        gemfile.puts("group :plugins do")

        plugins.each do |name, plugin|
          version = plugin["gem_version"]
          version = nil if version == ""

          opts = {}
          if plugin["require"] && plugin["require"] != ""
            opts[:require] = plugin["require"]
          end

          gemfile.puts(%Q[gem "#{name}", #{version.inspect}, #{opts.inspect}])
        end

        gemfile.puts("end")
        gemfile.close
      end
    end

    protected

    def with_isolated_gem
      # Remove bundler settings so that Bundler isn't loaded when building
      # native extensions because it causes all sorts of problems.
      old_rubyopt = ENV["RUBYOPT"]
      old_gemfile = ENV["BUNDLE_GEMFILE"]
      ENV["BUNDLE_GEMFILE"] = nil
      ENV["RUBYOPT"] = (ENV["RUBYOPT"] || "").gsub(/-rbundler\/setup\s*/, "")

      # Set the GEM_HOME so gems are installed only to our local gem dir
      ENV["GEM_HOME"] = Vagrant.user_data_path.join("gems").to_s

      # Clear paths so that it reads the new GEM_HOME setting
      Gem.paths = ENV

      # Set a custom configuration to avoid loading ~/.gemrc loads and
      # /etc/gemrc and so on.
      old_config = nil
      begin
        old_config = Gem.configuration
      rescue Psych::SyntaxError
        # Just ignore this. This means that the ".gemrc" file has
        # an invalid syntax and can't be loaded. We don't care, because
        # when we set Gem.configuration to nil later, it'll force a reload
        # if it is needed.
      end
      Gem.configuration = NilGemConfig.new

      # Use a silent UI so that we have no output
      Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
        return yield
      end
    ensure
      ENV["BUNDLE_GEMFILE"] = old_gemfile
      ENV["GEM_HOME"] = @gem_home
      ENV["RUBYOPT"]  = old_rubyopt

      Gem.configuration = old_config
      Gem.paths = ENV
    end

    # This is pretty hacky but it is a custom implementation of
    # Gem::ConfigFile so that we don't load any gemrc files.
    class NilGemConfig < Gem::ConfigFile
      def initialize
        # We _can not_ `super` here because that can really mess up
        # some other configuration state. We need to just set everything
        # directly.

        @api_keys       = {}
        @args           = []
        @backtrace      = false
        @bulk_threshold = 1000
        @hash           = {}
        @update_sources = true
        @verbose        = true
      end
    end
  end
end
