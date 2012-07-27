require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Vagrant::Action::General::Validate
          b.use CheckAccessible
        end
      end
    end
  end
end
