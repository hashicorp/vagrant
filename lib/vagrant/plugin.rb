require "rubygems"

module Vagrant
  class Plugin
    # The array of loaded plugins.
    @@plugins = []

    attr_reader :gemspec
    attr_reader :file

    # Loads all the plugins for Vagrant. Plugins are currently
    # gems which have a "vagrant_init.rb" somewhere on their
    # load path. This file is loaded to kick off the load sequence
    # for that plugin.
    def self.load!
      # Look for a vagrant_init.rb in all the gems, but only the
      # latest version of the gems.
      Gem.source_index.latest_specs.each do |spec|
        file = Gem.searcher.matching_files(spec, "vagrant_init.rb").first
        next if !file

        @@plugins << new(spec, file)
      end
    end

    # Returns the array of plugins which are currently loaded by
    # Vagrant.
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
