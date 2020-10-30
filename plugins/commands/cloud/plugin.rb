require "vagrant"
require 'vagrant_cloud'
require Vagrant.source_root.join("plugins/commands/cloud/util")
require Vagrant.source_root.join("plugins/commands/cloud/client/client")

module VagrantPlugins
  module CloudCommand
    class Plugin < Vagrant.plugin("2")
      name "vagrant-cloud"
      description <<-DESC
      Provides the cloud command and internal API access to Vagrant Cloud.
      DESC

      command(:cloud) do
        # Set this to match Vagant logging level so we get
        # desired request/response information within the
        # logger output
        ENV["VAGRANT_CLOUD_LOG"] = Vagrant.log_level

        require_relative "root"
        init!
        Command::Root
      end

      action_hook(:cloud_authenticated_boxes, :authenticate_box_url) do |hook|
        require_relative "auth/middleware/add_authentication"
        hook.prepend(AddAuthentication)
      end

      action_hook(:cloud_authenticated_boxes, :authenticate_box_downloader) do |hook|
        require_relative "auth/middleware/add_downloader_authentication"
        hook.prepend(AddDownloaderAuthentication)
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("../locales/en.yml", __FILE__)
        I18n.reload!
        @_init = true
      end
    end
  end
end
