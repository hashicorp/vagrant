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
        require File.expand_path("../../cloud/auth/login", __FILE__)
        init!
        VagrantPlugins::CloudCommand::AuthCommand::Command::Login
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("../../cloud/locales/en.yml", __FILE__)
        I18n.reload!
        @_init = true
      end
    end
  end
end
