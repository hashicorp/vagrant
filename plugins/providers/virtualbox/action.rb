require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)

      # Include the built-in modules so that we can use them as top-level
      # things.
      include Vagrant::Action::Builtin

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |result, b2|
            # `result` is a boolean true/false of whether the VM is created or
            # not. So if the VM _is_ created, then we continue with the
            # destruction.
            if result
              b2.use Vagrant::Action::General::Validate
              b2.use CheckAccessible
            end
          end
        end
      end
    end
  end
end
