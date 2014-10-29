require "vagrant"

module VagrantPlugins
  module HarmonyPush
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "harmony"
      description <<-DESC
      Deploy using HashiCorp's Harmony service.
      DESC

      config(:harmony, :push) do
        require File.expand_path("../config", __FILE__)
        init!
        Config
      end

      push(:harmony) do
        require File.expand_path("../push", __FILE__)
        init!
        Push
      end

      protected

      def self.init!
        return if defined?(@_init)
        I18n.load_path << File.expand_path(
          "templates/locales/TODO.yml", Vagrant.source_root)
        I18n.reload!
        @_init = true
      end
    end
  end
end
