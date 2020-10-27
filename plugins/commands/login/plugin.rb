require "vagrant"

module VagrantPlugins
  module LoginCommand
    class Plugin < Vagrant.plugin("2")
      name "vagrant-login"
      description <<-DESC
      Provides the login command and internal API access to Vagrant Cloud.
      DESC

      command(:login) do
        require File.expand_path("../../cloud/auth/login", __FILE__)
        VagrantPlugins::CloudCommand::AuthCommand::Command::Login
      end
    end
  end
end
