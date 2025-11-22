# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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
        init!
        VagrantPlugins::CloudCommand::AuthCommand::Command::Login
      end

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path("../../cloud/locales/en.yml", __FILE__)
        I18n.reload!
        @_init = true
      end
    end
  end
end
