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
        require_relative "config"
        init!
        Config
      end

      push(:harmony) do
        require_relative "push"
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
