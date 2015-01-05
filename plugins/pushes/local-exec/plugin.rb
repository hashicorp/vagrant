require "vagrant"

module VagrantPlugins
  module LocalExecPush
    class Plugin < Vagrant.plugin("2")
      name "local-exec"
      description <<-DESC
      Run a local command or script to push
      DESC

      config(:"local-exec", :push) do
        require File.expand_path("../config", __FILE__)
        init!
        Config
      end

      push(:"local-exec") do
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
