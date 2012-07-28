require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)

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

            # If the VM is created, then we confirm that we want to
            # destroy it.
            message = I18n.t("vagrant.commands.destroy.confirmation",
                             :name => env[:machine].name)
            confirm = Vagrant::Action::Builder.build(Confirm, message)

            b2.use Call, confirm do |env2, b3|
              if env2[:result]
                b3.use Vagrant::Action::General::Validate
                b3.use CheckAccessible
              else
                env2[:ui].info I18n.t("vagrant.commands.destroy.will_not_destroy",
                                      :name => env[:machine.name])
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
