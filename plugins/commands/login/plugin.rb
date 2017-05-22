require "vagrant"

module VagrantPlugins
  module LoginCommand
    autoload :Client, File.expand_path("../client", __FILE__)
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "vagrant-login"
      description <<-DESC
      Provides the login command and internal API access to Vagrant Cloud.
      DESC

      command(:login) do
        require_relative "command"
        init!
        Command
      end

      action_hook(:cloud_authenticated_boxes, :authenticate_box_url) do |hook|
        require_relative "middleware/add_authentication"
        hook.prepend(AddAuthentication)
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
