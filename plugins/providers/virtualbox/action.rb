require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :DestroyConfirm, File.expand_path("../action/destroy_confirm", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)
      autoload :MessageWillNotDestroy, File.expand_path("../action/message_will_not_destroy", __FILE__)

      # Include the built-in modules so that we can use them as top-level
      # things.
      include Vagrant::Action::Builtin

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::General::Validate
                b3.use CheckAccessible
              else
                b3.use MessageWillNotDestroy
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use DiscardState
              b2.use Halt
            else
              b2.use MessageNotCreated
            end
          end
        end
      end
    end
  end
end
