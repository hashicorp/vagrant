require "vagrant"

module VagrantPlugins
  module FTPPush
    class Plugin < Vagrant.plugin("2")
      name "ftp"
      description <<-DESC
      Deploy to a remote FTP or SFTP server.
      DESC

      config(:ftp, :push) do
        require File.expand_path("../config", __FILE__)
        init!
        Config
      end

      push(:ftp) do
        require File.expand_path("../push", __FILE__)
        init!
        Push
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
