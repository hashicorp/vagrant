require "rubygems"

require "log4r"

module Vagrant
  # Represents a single plugin and also manages loading plugins from
  # RubyGems. If a plugin has a `vagrant_init.rb` file somewhere on its
  # load path, then this class will find it and load it. For logging purposes
  # (for debugging), the list of loaded plugins is stored in the {plugins}
  # array.
  class Plugin
    # The array of gem specifications that were loaded as plugins.
    @@plugins = []

    # Loads all the plugins for Vagrant. Plugins are currently
    # gems which have a "vagrant_init.rb" somewhere on their
    # load path. This file is loaded to kick off the load sequence
    # for that plugin.
    def self.load!
      logger = Log4r::Logger.new("vagrant::plugin")
      logger.info("Searching and loading any available plugins...")

      # Our version is used for checking dependencies
      our_version = Gem::Version.create(Vagrant::VERSION)

      # RubyGems 1.8.0 deprecated `source_index`. Gem::Specification is the
      # new replacement. For now, we support both, but special-case 1.8.x
      # so that we avoid deprecation messages.
      index = Gem::VERSION >= "1.8.0" ? Gem::Specification : Gem.source_index

      # Stupid hack since Rails 2.3.x overrides Gem.source_index with their
      # own incomplete replacement which causes issues.
      index = [index.installed_source_index, index.vendor_source_index] if defined?(Rails::VendorGemSourceIndex) && index.is_a?(Rails::VendorGemSourceIndex)

      # Look for a vagrant_init.rb in all the gems, but only the
      # latest version of the gems.
      [index].flatten.each do |source|
        # In 1.6.0, added the option of including prerelease gems, which is
        # useful for developers.
        specs = Gem::VERSION >= "1.6.0" ? source.latest_specs(true) : source.latest_specs

        specs.each do |spec|
          if @@plugins.include?(spec)
            logger.debug("Plugin already loaded, not loading again: #{spec.name}")
            next
          end

          # If this gem depends on Vagrant, verify this is a valid release of
          # Vagrant for this gem to load into.
          vagrant_dep = spec.dependencies.find { |d| d.name == "vagrant" }
          if vagrant_dep && !vagrant_dep.requirement.satisfied_by?(our_version)
            logger.debug("Plugin Vagrant dependency mismatch: #{spec.name} (#{spec.version})")
            next
          end

          # Find a vagrant_init.rb to verify if this is a plugin
          file = nil
          if Gem::VERSION >= "1.8.0"
            file = spec.matches_for_glob("**/vagrant_init.rb").first
          else
            file = Gem.searcher.matching_files(spec, "vagrant_init.rb").first
          end

          next if !file

          logger.info("Loading plugin: #{spec.name} (#{spec.version})")
          @@plugins << spec
          load file
        end

        logger.info("Loaded #{@@plugins.length} plugins.")
      end
    end

    # Returns the array of plugins which are currently loaded by
    # Vagrant.
    #
    # @return [Array]
    def self.plugins; @@plugins; end
  end
end
