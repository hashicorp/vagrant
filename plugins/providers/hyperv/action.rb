require "pathname"

require "vagrant/action/builder"

module VagrantPlugins
  module HyperV
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use action_halt
            b2.use action_start
          end
        end
      end

      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsCreated do |env1, b1|
            if !env1[:result]
              b1.use MessageNotCreated
              next
            end

            b1.use Call, DestroyConfirm do |env2, b2|
              if !env2[:result]
                b2.use MessageWillNotDestroy
                next
              end

              b2.use ConfigValidate
              b2.use StopInstance
              b2.use DeleteVM
            end
          end
        end
      end

      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, GracefulHalt, :off, :running do |env2, b3|
              if !env2[:result]
                b3.use StopInstance
              end
            end
          end
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use Provision
          b.use StartInstance
          b.use WaitForIPAddress
          b.use WaitForCommunicator, [:running]
          b.use SyncedFolders
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBox
          b.use ConfigValidate
          b.use Call, IsCreated do |env1, b1|
            if !env1[:result]
              b1.use Import
            end

            b1.use action_start
          end
        end
      end

      def self.action_read_state
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadState
        end
      end

      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsCreated do |env, b2|
            if !env[:result]
              b2.use MessageNotCreated
              next
            end
            b2.use Call, IsStopped do |env1, b3|
              if env1[:result]
                b3.use MessageNotRunning
              else
                b3.use SSHExec
              end
            end
          end
        end
      end

      def self.action_read_guest_ip
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use ReadGuestIP
        end
      end


      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :DeleteVM, action_root.join("delete_vm")
      autoload :IsCreated, action_root.join("is_created")
      autoload :IsStopped, action_root.join("is_stopped")
      autoload :ReadState, action_root.join("read_state")
      autoload :Import, action_root.join("import")
      autoload :StartInstance, action_root.join('start_instance')
      autoload :StopInstance, action_root.join('stop_instance')
      autoload :MessageNotCreated, action_root.join('message_not_created')
      autoload :MessageAlreadyCreated, action_root.join('message_already_created')
      autoload :MessageNotRunning, action_root.join('message_not_running')
      autoload :SyncFolders, action_root.join('sync_folders')
      autoload :ReadGuestIP, action_root.join('read_guest_ip')
      autoload :WaitForIPAddress, action_root.join("wait_for_ip_address")
    end
  end
end
