require "vagrant"

module VagrantPlugins
  module AtlasPush
    autoload :Errors, File.expand_path("../errors", __FILE__)

    class Plugin < Vagrant.plugin("2")
      name "atlas"
      description <<-DESC
      Deploy using HashiCorp's Atlas service.
      DESC

      config(:atlas, :push) do
        require_relative "config"
        init!
        Config
      end

      push(:atlas) do
        require_relative "push"
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
