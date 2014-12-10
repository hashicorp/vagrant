require "vagrant"

module VagrantPlugins
  module HerokuPush
    class Plugin < Vagrant.plugin("2")
      name "heroku"
      description <<-DESC
      Deploy to a Heroku
      DESC

      config(:heroku, :push) do
        require File.expand_path("../config", __FILE__)
        init!
        Config
      end

      push(:heroku) do
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
