require "vagrant"

require 'vagrant/util/platform'

module VagrantPlugins
  module HostWindows
    class Host < Vagrant.plugin("2", :host)
      def detect?(env)
        Vagrant::Util::Platform.windows?
      end

      # @return [Pathname] Path to scripts directory
      def self.scripts_path
        Pathname.new(File.expand_path("../scripts", __FILE__))
      end

      # @return [Pathname] Path to modules directory
      def self.modules_path
        scripts_path.join("utils")
      end
    end
  end
end
