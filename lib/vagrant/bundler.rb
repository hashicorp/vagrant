require "monitor"
require "pathname"
require "set"
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
      @enabled = true if ENV["VAGRANT_INSTALLER_ENV"] ||
        ENV["VAGRANT_FORCE_BUNDLER"]
      @enabled  = !::Bundler::SharedHelpers.in_bundle? if !@enabled
      @monitor  = Monitor.new

      @gem_home = ENV["GEM_HOME"]
      @gem_path = ENV["GEM_PATH"]

      # Set the Bundler UI to be a silent UI. We have to add the
      # `silence` method to it because Bundler UI doesn't have it.
      ::Bundler.ui =
        if ::Bundler::UI.const_defined? :Silent
          # bundler >= 1.6.0, we use our custom UI
          BundlerUI.new
        else
          # bundler < 1.6.0
          ::Bundler::UI.new
        end
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
      # If we're not enabled, then we don't do anything.
      return if !@enabled

      bundle_path = Vagrant.user_data_path.join("gems")

      # Setup the "local" Bundler configuration. We need to set BUNDLE_PATH
      # because the existence of this actually suppresses `sudo`.
      @appconfigpath = Dir.mktmpdir
      File.open(File.join(@appconfigpath, "config"), "w+") do |f|
        f.write("BUNDLE_PATH: \"#{bundle_path}\"")
      end

      # Setup the Bundler configuration
      @configfile = File.open(Tempfile.new("vagrant").path + "1", "w+")
      @configfile.close

      # Build up the Gemfile for our Bundler context. We make sure to
      # lock Vagrant to our current Vagrant version. In addition to that,
      # we add all our plugin dependencies.
      @gemfile = build_gemfile(plugins)

      # Set the environmental variables for Bundler
      ENV["BUNDLE_APP_CONFIG"] = @appconfigpath
      ENV["BUNDLE_CONFIG"]  = @configfile.path
      ENV["BUNDLE_GEMFILE"] = @gemfile.path
      ENV["GEM_PATH"] =
        "#{bundle_path}#{::File::PATH_SEPARATOR}#{@gem_path}"
      Gem.clear_paths
    end

    # Removes any temporary files created by init
    def deinit
      File.unlink(ENV["BUNDLE_APP_CONFIG"]) rescue nil
      File.unlink(ENV["BUNDLE_CONFIG"]) rescue nil
      File.unlink(ENV["GEMFILE"]) rescue nil
    end

    # Installs the list of plugins.
    #
    # @param [Hash] plugins
    # @return [Array<Gem::Specification>]
    def install(plugins, local=false)
      internal_install(plugins, nil, local: local)
    end

    # Installs a local '*.gem' file so that Bundler can find it.
    #
    # @param [String] path Path to a local gem file.
    # @return [Gem::Specification]
    def install_local(path)
      # We have to do this load here because this file can be loaded
      # before RubyGems is actually loaded.
      require "rubygems/dependency_installer"
      begin
        require "rubygems/format"
      rescue LoadError
        # rubygems 2.x
      end

      # If we're installing from a gem file, determine the name
      # based on the spec in the file.
      pkg = if defined?(Gem::Format)
              # RubyGems 1.x
              Gem::Format.from_file_by_path(path)
            else
              # RubyGems 2.x
              Gem::Package.new(path)
            end

      # Install the gem manually. If the gem exists locally, then
      # Bundler shouldn't attempt to get it remotely.
      with_isolated_gem do
        installer = Gem::DependencyInstaller.new(
          document: [], prerelease: false)
        installer.install(path, "= #{pkg.spec.version}")
      end

      pkg.spec
    end

    # Update updates the given plugins, or every plugin if none is given.
    #
    # @param [Hash] plugins
    # @param [Array<String>] specific Specific plugin names to update. If
    #   empty or nil, all plugins will be updated.
    def update(plugins, specific)
      specific ||= []
      update = true
      update = { gems: specific } if !specific.empty?
      internal_install(plugins, update)
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

    # During the duration of the yielded block, Bundler loud output
    # is enabled.
    def verbose
      @monitor.synchronize do
        begin
          old_ui = ::Bundler.ui
          require 'bundler/vendored_thor'
          ::Bundler.ui = ::Bundler::UI::Shell.new
          yield
        ensure
          ::Bundler.ui = old_ui
        end
      end
    end

    protected

    # Builds a valid Gemfile for use with Bundler given the list of
    # plugins.
    #
    # @return [Tempfile]
    def build_gemfile(plugins)
      sources = plugins.values.map { |p| p["sources"] }.flatten.compact.uniq

      f = File.open(Tempfile.new("vagrant").path + "2", "w+")
      f.tap do |gemfile|
        if !sources.include?("http://rubygems.org")
          gemfile.puts(%Q[source "https://rubygems.org"])
        end

        gemfile.puts(%Q[source "http://gems.hashicorp.com"])
        sources.each do |source|
          next if source == ""
          gemfile.puts(%Q[source "#{source}"])
        end

        gemfile.puts(%Q[gem "vagrant", "= #{VERSION}"])

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

    # This installs a set of plugins and optionally updates those gems.
    #
    # @param [Hash] plugins
    # @param [Hash, Boolean] update If true, updates all plugins, otherwise
    #   can be a hash of options. See Bundler.definition.
    # @return [Array<Gem::Specification>]
    def internal_install(plugins, update, **extra)
      gemfile    = build_gemfile(plugins)
      lockfile   = "#{gemfile.path}.lock"
      definition = ::Bundler::Definition.build(gemfile, lockfile, update)
      root       = File.dirname(gemfile.path)
      opts       = {}
      opts["local"] = true if extra[:local]

      with_isolated_gem do
        ::Bundler::Installer.install(root, definition, opts)
      end

      # TODO(mitchellh): clean gems here... for some reason when I put
      # it in on install, we get a GemNotFound exception. Gotta investigate.

      definition.specs
    rescue ::Bundler::VersionConflict => e
      raise Errors::PluginInstallVersionConflict,
        conflicts: e.to_s.gsub("Bundler", "Vagrant")
    rescue ::Bundler::BundlerError => e
      if !::Bundler.ui.is_a?(BundlerUI)
        raise
      end

      # Add the warn/error level output from Bundler if we have any
      message = "#{e.message}"
      if ::Bundler.ui.output != ""
        message += "\n\n#{::Bundler.ui.output}"
      end

      raise ::Bundler::BundlerError, message
    end

    def with_isolated_gem
      raise Errors::BundlerDisabled if !@enabled

      # Remove bundler settings so that Bundler isn't loaded when building
      # native extensions because it causes all sorts of problems.
      old_rubyopt = ENV["RUBYOPT"]
      old_gemfile = ENV["BUNDLE_GEMFILE"]
      ENV["BUNDLE_GEMFILE"] = Tempfile.new("vagrant-gemfile").path
      ENV["RUBYOPT"] = (ENV["RUBYOPT"] || "").gsub(/-rbundler\/setup\s*/, "")

      # Set the GEM_HOME so gems are installed only to our local gem dir
      ENV["GEM_HOME"] = Vagrant.user_data_path.join("gems").to_s

      # Clear paths so that it reads the new GEM_HOME setting
      Gem.paths = ENV

      # Reset the all specs override that Bundler does
      old_all = Gem::Specification._all
      Gem::Specification.all = nil

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
      Gem::Specification.all = old_all
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

    if ::Bundler::UI.const_defined? :Silent
      class BundlerUI < ::Bundler::UI::Silent
        attr_reader :output

        def initialize
          @output = ""
        end

        def info(message, newline = nil)
        end

        def confirm(message, newline = nil)
        end

        def warn(message, newline = nil)
          @output += message
          @output += "\n" if newline
        end

        def error(message, newline = nil)
          @output += message
          @output += "\n" if newline
        end

        def debug(message, newline = nil)
        end

        def debug?
          false
        end

        def quiet?
          false
        end

        def ask(message)
        end

        def level=(name)
        end

        def level(name = nil)
          "info"
        end

        def trace(message, newline = nil)
        end

        def silence
          yield
        end
      end
    end
  end
end
