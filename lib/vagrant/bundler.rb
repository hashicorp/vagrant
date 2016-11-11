require "monitor"
require "pathname"
require "set"
require "tempfile"
require "fileutils"

require "rubygems/package"
require "rubygems/uninstaller"

require_relative "shared_helpers"
require_relative "version"
require_relative "util/safe_env"

module Vagrant
  # This class manages Vagrant's interaction with Bundler. Vagrant uses
  # Bundler as a way to properly resolve all dependencies of Vagrant and
  # all Vagrant-installed plugins.
  class Bundler

    HASHICORP_GEMSTORE = 'https://gems.hashicorp.com'.freeze

    def self.instance
      @bundler ||= self.new
    end

    attr_reader :plugin_gem_path

    def initialize
      @plugin_gem_path = Vagrant.user_data_path.join("gems", RUBY_VERSION).freeze
      @logger = Log4r::Logger.new("vagrant::bundler")
    end

    # Initializes Bundler and the various gem paths so that we can begin
    # loading gems. This must only be called once.
    def init!(plugins, repair=false)
      # Add HashiCorp RubyGems source
      Gem.sources << HASHICORP_GEMSTORE

      # Generate dependencies for all registered plugins
      plugin_deps = plugins.map do |name, info|
        Gem::Dependency.new(name, info['gem_version'].to_s.empty? ? '> 0' : info['gem_version'])
      end

      @logger.debug("Current generated plugin dependency list: #{plugin_deps}")

      # Load dependencies into a request set for resolution
      request_set = Gem::RequestSet.new(*plugin_deps)
      # Never allow dependencies to be remotely satisfied during init
      request_set.remote = false

      # Sets that we can resolve our dependencies from
      current_set = Gem::Resolver::CurrentSet.new
      plugin_set = Gem::Resolver::VendorSet.new
      repair_result = nil
      begin
        # Register all known plugin specifications to the plugin set
        Dir.glob(plugin_gem_path.join('specifications/*.gemspec').to_s).each do |spec_path|
          spec = Gem::Specification.load(spec_path)
          desired_spec_path = File.join(spec.gem_dir, "#{spec.name}.gemspec")
          # Vendor set requires the spec to be within the gem directory. Some gems will package their
          # spec file, and that's not what we want to load.
          if !File.exist?(desired_spec_path) || !FileUtils.cmp(spec.spec_file, desired_spec_path)
            File.write(desired_spec_path, spec.to_ruby)
          end
          plugin_set.add_vendor_gem(spec.name, spec.gem_dir)
        end

        # Compose set for resolution
        composed_set = Gem::Resolver.compose_sets(current_set, plugin_set)

        @logger.debug("Composed local RubyGems set for plugin init resolution: #{composed_set}")

        # Resolve the request set to ensure proper activation order
        solution = request_set.resolve(composed_set)
      rescue Gem::UnsatisfiableDependencyError => failure
        if repair
          raise failure if @init_retried
          @logger.debug("Resolution failed but attempting to repair. Failure: #{failure}")
          install(plugins)
          @init_retried = true
          retry
        else
          @logger.debug("#{failure.class}: #{failure}")
          $stderr.puts "Vagrant failed to properly initialize due to an error while"
          $stderr.puts "while attempting to load configured plugins. This can be caused"
          $stderr.puts "by manually tampering with the 'plugins.json' file, or by a"
          $stderr.puts "recent Vagrant upgrade. To fix this problem, please run:\n\n"
          $stderr.puts "    vagrant plugin repair\n\n"
          $stderr.puts "The error message is shown below:\n\n"
          $stderr.puts failure.message
          exit 1
        end
      end

      @logger.debug("Initialization solution set: #{solution.map(&:full_name)}")

      # Activate the gems
      begin
        retried = false
        solution.each do |activation_request|
          unless activation_request.full_spec.activated?
            @logger.debug("Activating gem #{activation_request.full_spec.full_name}")
            activation_request.full_spec.activate
            if(defined?(::Bundler))
              @logger.debug("Marking gem #{activation_request.full_spec.full_name} loaded within Bundler.")
              ::Bundler.rubygems.mark_loaded activation_request.full_spec
            end
          end
        end
      rescue Gem::LoadError
        # Depending on the version of Ruby, the ordering of the solution set
        # will be either 0..n (molinillo) or n..0 (pre-molinillo). Instead of
        # attempting to determine what's in use, or if it has some how changed
        # again, just reverse order on failure and attempt again.
        if retried
          raise
        else
          retried = true
          solution.reverse!
          retry
        end
      end

      full_vagrant_spec_list = Gem::Specification.find_all{true} +
        solution.map(&:full_spec)

      if(defined?(::Bundler))
        @logger.debug("Updating Bundler with full specification list")
        ::Bundler.rubygems.replace_entrypoints(full_vagrant_spec_list)
      end

      Gem.post_reset do
        Gem::Specification.all = full_vagrant_spec_list
      end
    end

    # Removes any temporary files created by init
    def deinit
      # no-op
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
    def install_local(path, opts={})
      plugin_source = Gem::Source::SpecificFile.new(path)
      plugin_info = {
        plugin_source.spec.name => {
          "local_source" => plugin_source,
          "sources" => opts.fetch(:sources, Gem.sources.map(&:to_s))
        }
      }
      @logger.debug("Installing local plugin - #{plugin_info}")
      internal_install(plugin_info, {})
      plugin_source.spec
    end

    # Update updates the given plugins, or every plugin if none is given.
    #
    # @param [Hash] plugins
    # @param [Array<String>] specific Specific plugin names to update. If
    #   empty or nil, all plugins will be updated.
    def update(plugins, specific)
      specific ||= []
      update = { gems: specific } if !specific.empty?
      internal_install(plugins, update)
    end

    # Clean removes any unused gems.
    def clean(plugins)
      # Generate dependencies for all registered plugins
      plugin_deps = plugins.map do |name, info|
        Gem::Dependency.new(name, info['gem_version'].to_s.empty? ? '> 0' : info['gem_version'])
      end

      # Load dependencies into a request set for resolution
      request_set = Gem::RequestSet.new(*plugin_deps)
      # Never allow dependencies to be remotely satisfied during cleaning
      request_set.remote = false

      # Sets that we can resolve our dependencies from. Note that we only
      # resolve from the current set as all required deps are activated during
      # init.
      current_set = Gem::Resolver::CurrentSet.new

      # Collect all plugin specifications
      plugin_specs = Dir.glob(plugin_gem_path.join('specifications/*.gemspec').to_s).map do |spec_path|
        Gem::Specification.load(spec_path)
      end

      # Resolve the request set to ensure proper activation order
      solution = request_set.resolve(current_set)
      solution_specs = solution.map(&:full_spec)

      # Find all specs installed to plugins directory that are not
      # found within the solution set
      plugin_specs.delete_if do |spec|
        solution.include?(spec)
      end

      # Now delete all unused specs
      plugin_specs.each do |spec|
        Gem::Uninstaller.new(spec.name,
          version: spec.version,
          install_dir: plugin_gem_path,
          ignore: true
        ).uninstall_gem(spec)
      end

      solution.find_all do |spec|
        plugins.keys.include?(spec.name)
      end
    end

    # During the duration of the yielded block, Bundler loud output
    # is enabled.
    def verbose
      if block_given?
        initial_state = @verbose
        @verbose = true
        yield
        @verbose = initial_state
      else
        @verbose = true
      end
    end

    protected

    def internal_install(plugins, update, **extra)
      # Only allow defined Gem sources
      Gem.sources.clear

      update = {} unless update.is_a?(Hash)
      installer_set = Gem::Resolver::InstallerSet.new(:both)

      # Generate all required plugin deps
      plugin_deps = plugins.map do |name, info|
        if update == true || (update[:gems].respond_to?(:include?) && update[:gems].include?(name))
          gem_version = '> 0'
        else
          gem_version = info['gem_version'].to_s.empty? ? '> 0' : info['gem_version']
        end
        if plugin_source = info.delete("local_source")
          installer_set.add_local(plugin_source.spec.name, plugin_source.spec, plugin_source)
        end
        Array(info["sources"]).each do |source|
          if !Gem.sources.include?(source)
            @logger.debug("Adding RubyGems source for plugin install: #{source}")
            Gem.sources << source
          end
        end
        Gem::Dependency.new(name, gem_version)
      end

      @logger.debug("Dependency list for installation: #{plugin_deps}")

      # Create the request set for the new plugins
      request_set = Gem::RequestSet.new(*plugin_deps)

      # Generate all existing deps within the "vagrant system"
      existing_deps = Gem::Specification.find_all{true}.map do |item|
        Gem::Dependency.new(item.name, item.version)
      end

      # Import constraints into the request set to prevent installing
      # gems that are incompatible with the core system
      request_set.import(existing_deps)

      # Generate the required solution set for new plugins
      solution = request_set.resolve(installer_set)

      @logger.debug("Generated solution set: #{solution.map(&:full_name)}")

      # If any items in the solution set are local but not activated, turn them on
      solution.each do |activation_request|
        if activation_request.installed? && !activation_request.full_spec.activated?
          @logger.debug("Activating gem specification: #{activation_request.full_spec.full_name}")
          activation_request.full_spec.activate
        end
      end

      # Install all remote gems into plugin path. Set the installer to ignore dependencies
      # as we know the dependencies are satisfied and it will attempt to validate a gem's
      # dependencies are satisified by gems in the install directory (which will likely not
      # be true)
      result = request_set.install_into(plugin_gem_path.to_s, true, ignore_dependencies: true)
      result.map(&:full_spec)
    end

  end
end
