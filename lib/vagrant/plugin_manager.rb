require "json"

require_relative "paths"

module Vagrant
  class PluginManager
    def self.global_plugins_file
      Vagrant.user_data_path.join("plugins.json")
    end

    def self.plugins
      plugins = JSON.parse(global_plugins_file.read)
      plugins["installed"].keys
    end
  end
end
