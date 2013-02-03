require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module CommandPlugin
    module Action
      # This middleware sequence will install a plugin.
      def self.action_install
        Vagrant::Action::Builder.new.tap do |b|
          b.use BundlerCheck
          b.use InstallGem
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :BundlerCheck, action_root.join("bundler_check")
      autoload :InstallGem, action_root.join("install_gem")
    end
  end
end
