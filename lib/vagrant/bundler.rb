require "monitor"
require "pathname"
require "set"
require "tempfile"
require "fileutils"

require "rubygems/package"
require "rubygems/uninstaller"
require "rubygems/name_tuple"

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

      repair_result = nil
      begin
        # Compose set for resolution
        composed_set = generate_vagrant_set
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
          raise
        end
      end

      # Activate the gems
      activate_solution(solution)

      full_vagrant_spec_list = Gem::Specification.find_all{true} +
        solution.map(&:full_spec)

      if(defined?(::Bundler))
        @logger.debug("Updating Bundler with full specification list")
        ::Bundler.rubygems.replace_entrypoints(full_vagrant_spec_list)
      end

      Gem.post_reset do
        Gem::Specification.all = full_vagrant_spec_list
      end

      Gem::Specification.reset
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
      update = {gems: specific.empty? ? true : specific}
      internal_install(plugins, update)
    end

    # Clean removes any unused gems.
    def clean(plugins)
      @logger.debug("Cleaning Vagrant plugins of stale gems.")
      # Generate dependencies for all registered plugins
      plugin_deps = plugins.map do |name, info|
        gem_version = info['installed_gem_version']
        gem_version = info['gem_version'] if gem_version.to_s.empty?
        gem_version = "> 0" if gem_version.to_s.empty?
        Gem::Dependency.new(name, gem_version)
      end

      @logger.debug("Current plugin dependency list: #{plugin_deps}")

      # Load dependencies into a request set for resolution
      request_set = Gem::RequestSet.new(*plugin_deps)
      # Never allow dependencies to be remotely satisfied during cleaning
      request_set.remote = false

      # Sets that we can resolve our dependencies from. Note that we only
      # resolve from the current set as all required deps are activated during
      # init.
      current_set = generate_vagrant_set

      # Collect all plugin specifications
      plugin_specs = Dir.glob(plugin_gem_path.join('specifications/*.gemspec').to_s).map do |spec_path|
        Gem::Specification.load(spec_path)
      end

      @logger.debug("Generating current plugin state solution set.")

      # Resolve the request set to ensure proper activation order
      solution = request_set.resolve(current_set)
      solution_specs = solution.map(&:full_spec)
      solution_full_names = solution_specs.map(&:full_name)

      # Find all specs installed to plugins directory that are not
      # found within the solution set
      plugin_specs.delete_if do |spec|
        solution_full_names.include?(spec.full_name)
      end

      @logger.debug("Specifications to be removed - #{plugin_specs.map(&:full_name)}")

      # Now delete all unused specs
      plugin_specs.each do |spec|
        @logger.debug("Uninstalling gem - #{spec.full_name}")
        Gem::Uninstaller.new(spec.name,
          version: spec.version,
          install_dir: plugin_gem_path,
          all: true,
          executables: true,
          force: true,
          ignore: true,
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

      update = {} if !update.is_a?(Hash)
      skips = []
      installer_set = Gem::Resolver::InstallerSet.new(:both)

      # Generate all required plugin deps
      plugin_deps = plugins.map do |name, info|
        if update[:gems] == true || (update[:gems].respond_to?(:include?) && update[:gems].include?(name))
          gem_version = '> 0'
          skips << name
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

      installer_set = Gem::Resolver.compose_sets(
        installer_set,
        generate_builtin_set,
        generate_plugin_set(skips)
      )

      @logger.debug("Generating solution set for installation.")

      # Generate the required solution set for new plugins
      solution = request_set.resolve(installer_set)
      activate_solution(solution)

      @logger.debug("Installing required gems.")

      # Install all remote gems into plugin path. Set the installer to ignore dependencies
      # as we know the dependencies are satisfied and it will attempt to validate a gem's
      # dependencies are satisified by gems in the install directory (which will likely not
      # be true)
      result = request_set.install_into(plugin_gem_path.to_s, true, ignore_dependencies: true)
      result = result.map(&:full_spec)
      result
    end

    # Generate the composite resolver set totally all of vagrant (builtin + plugin set)
    def generate_vagrant_set
      Gem::Resolver.compose_sets(generate_builtin_set, generate_plugin_set)
    end

    # @return [Array<[Gem::Specification, String]>] spec and directory pairs
    def vagrant_internal_specs
      list = {}
      directories = [Gem::Specification.default_specifications_dir]
      Gem::Specification.find_all{true}.each do |spec|
        list[spec.full_name] = spec
      end
      if(!defined?(::Bundler))
        directories += Gem::Specification.dirs.find_all do |path|
          !path.start_with?(Gem.user_dir)
        end
      end
      Gem::Specification.each_spec(directories) do |spec|
        if !list[spec.full_name]
          list[spec.full_name] = spec
        end
      end
      list.values
    end

    # Generate the builtin resolver set
    def generate_builtin_set
      builtin_set = BuiltinSet.new
      @logger.debug("Generating new builtin set instance.")
      vagrant_internal_specs.each do |spec|
        builtin_set.add_builtin_spec(spec)
      end
      builtin_set
    end

    # Generate the plugin resolver set. Optionally provide specification names (short or
    # full) that should be ignored
    def generate_plugin_set(skip=[])
      plugin_set = PluginSet.new
      @logger.debug("Generating new plugin set instance. Skip gems - #{skip}")
      Dir.glob(plugin_gem_path.join('specifications/*.gemspec').to_s).each do |spec_path|
        spec = Gem::Specification.load(spec_path)
        desired_spec_path = File.join(spec.gem_dir, "#{spec.name}.gemspec")
        # Vendor set requires the spec to be within the gem directory. Some gems will package their
        # spec file, and that's not what we want to load.
        if !File.exist?(desired_spec_path) || !FileUtils.cmp(spec.spec_file, desired_spec_path)
          File.write(desired_spec_path, spec.to_ruby)
        end
        next if skip.include?(spec.name) || skip.include?(spec.full_name)
        plugin_set.add_vendor_gem(spec.name, spec.gem_dir)
      end
      plugin_set
    end

    # Activate a given solution
    def activate_solution(solution)
      retried = false
      begin
        @logger.debug("Activating solution set: #{solution.map(&:full_name)}")
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
      rescue Gem::LoadError => e
        # Depending on the version of Ruby, the ordering of the solution set
        # will be either 0..n (molinillo) or n..0 (pre-molinillo). Instead of
        # attempting to determine what's in use, or if it has some how changed
        # again, just reverse order on failure and attempt again.
        if retried
          @logger.error("Failed to load solution set - #{e.class}: #{e}")
          matcher = e.message.match(/Could not find '(?<gem_name>[^']+)'/)
          if matcher && !matcher["gem_name"].empty?
            desired_activation_request = solution.detect do |request|
              request.name == matcher["gem_name"]
            end
            if desired_activation_request && !desired_activation_request.full_spec.activated?
              activation_request = desired_activation_request
              @logger.warn("Found misordered activation request for #{desired_activation_request.full_name}. Moving to solution HEAD.")
              solution.delete(desired_activation_request)
              solution.unshift(desired_activation_request)
              retry
            end
          end

          raise
        else
          @logger.debug("Failed to load solution set. Retrying with reverse order.")
          retried = true
          solution.reverse!
          retry
        end
      end
    end

    # This is a custom Gem::Resolver::Set for use with vagrant "system" gems. It
    # allows the installed set of gems to be used for providing a solution while
    # enforcing strict constraints. This ensures that plugins cannot "upgrade"
    # gems that are builtin to vagrant itself.
    class BuiltinSet < Gem::Resolver::Set
      def initialize
        super
        @remote = false
        @specs = []
      end

      def add_builtin_spec(spec)
        @specs.push(spec).uniq!
      end

      def find_all(req)
        @specs.select do |spec|
          req.match?(spec)
        end.map do |spec|
          Gem::Resolver::InstalledSpecification.new(self, spec)
        end
      end
    end

    # This is a custom Gem::Resolver::Set for use with Vagrant plugins. It is
    # a modified Gem::Resolver::VendorSet that supports multiple versions of
    # a specific gem
    class PluginSet < Gem::Resolver::VendorSet
      ##
      # Adds a specification to the set with the given +name+ which has been
      # unpacked into the given +directory+.
      def add_vendor_gem(name, directory)
        gemspec = File.join(directory, "#{name}.gemspec")
        spec = Gem::Specification.load(gemspec)
        if !spec
          raise Gem::GemNotFoundException,
            "unable to find #{gemspec} for gem #{name}"
        end

        spec.full_gem_path = File.expand_path(directory)

        @specs[spec.name] ||= []
        @specs[spec.name] << spec
        @directories[spec] = directory

        spec
      end

      ##
      # Returns an Array of VendorSpecification objects matching the
      # DependencyRequest +req+.
      def find_all(req)
        @specs.values.flatten.select do |spec|
          req.match?(spec)
        end.map do |spec|
          source = Gem::Source::Vendor.new(@directories[spec])
          Gem::Resolver::VendorSpecification.new(self, spec, source)
        end
      end

      ##
      # Loads a spec with the given +name+. +version+, +platform+ and +source+ are
      # ignored.
      def load_spec (name, version, platform, source)
        version = Gem::Version.new(version) if !version.is_a?(Gem::Version)
        @specs.fetch(name, []).detect{|s| s.name == name && s.version = version}
      end
    end
  end
end

# Patch for Ruby 2.2 and Bundler to behave properly when uninstalling plugins
if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.3')
  if defined?(::Bundler) && !::Bundler::SpecSet.instance_methods.include?(:delete)
    class Gem::Specification
      def self.remove_spec(spec)
        Gem::Specification.reset
      end
    end
  end
end
