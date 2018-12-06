module Vagrant
  module GoPlugin

    # @return [String]
    INSTALL_DIRECTORY = Vagrant.user_data_path.join("go-plugins").to_s.freeze

    autoload :CapabilityPlugin, "vagrant/go_plugin/capability_plugin"
    autoload :ConfigPlugin, "vagrant/go_plugin/config_plugin"
    autoload :Core, "vagrant/go_plugin/core"
    autoload :Interface, "vagrant/go_plugin/interface"
    autoload :Manager, "vagrant/go_plugin/manager"
    autoload :ProviderPlugin, "vagrant/go_plugin/provider_plugin"
    autoload :SyncedFolderPlugin, "vagrant/go_plugin/synced_folder_plugin"

    # @return [Interface]
    def self.interface
      unless @_interface
        @_interface = Interface.new
      end
      @_interface
    end
  end
end
