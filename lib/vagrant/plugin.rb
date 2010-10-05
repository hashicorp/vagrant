require "rubygems"

module Vagrant
  # Represents a single plugin and also manages loading plugins from
  # RubyGems. If a plugin has a `vagrant_init.rb` file somewhere on its
  # load path, then this class will find it and load it. For logging purposes
  # (for debugging), the list of loaded plugins is stored in the {plugins}
  # array.
  class Plugin
    # The array of loaded plugins.
    @@plugins = []

    # The gemspec of this plugin. This is an actual gemspec object.
    attr_reader :gemspec

    # The path to the `vagrant_init.rb` file which was loaded for this plugin.
    attr_reader :file

    # Loads all the plugins for Vagrant. Plugins are currently
    # gems which have a "vagrant_init.rb" somewhere on their
    # load path. This file is loaded to kick off the load sequence
    # for that plugin.
    def self.load!
      # Stupid hack since Rails 2.3.x overrides Gem.source_index with their
      # own incomplete replacement which causes issues.
      index = Gem.source_index
      index = [index.installed_source_index, index.vendor_source_index] if defined?(Rails::VendorGemSourceIndex) && index.is_a?(Rails::VendorGemSourceIndex)

      # Look for a vagrant_init.rb in all the gems, but only the
      # latest version of the gems.
      [index].flatten.each do |source|
        source.latest_specs.each do |spec|
          file = Gem.searcher.matching_files(spec, "vagrant_init.rb").first
          next if !file

          @@plugins << new(spec, file)
        end
      end
    end

    # Returns the array of plugins which are currently loaded by
    # Vagrant.
    #
    # @return [Array]
    def self.plugins; @@plugins; end

    # Initializes a new plugin, given a Gemspec and the path to the
    # gem's `vagrant_init.rb` file. This should never be called manually.
    # Instead {load!} creates all the instances.
    def initialize(spec, file)
      @gemspec = spec
      @file = file

      load file
    end
  end
end
