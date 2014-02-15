#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

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
            b2.use Call, WaitForState, :off, 120 do |env2, b3|
              if env2[:result]
                b3.use action_up
              else
                env2[:ui].info("Machine did not reload, Check machine's status")
              end
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
            b2.use StopInstance
          end
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use StartInstance
          b.use ShareFolders
          b.use SyncFolders
        end
      end

      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use HandleBoxUrl
          b.use ConfigValidate
          b.use Call, IsCreated do |env1, b1|
            if env1[:result]
              b1.use Call, IsStopped do |env2, b2|
                if env2[:result]
                  b2.use action_start
                else
                  b2.use MessageAlreadyCreated
                end
              end
            else
              b1.use Import
              b1.use action_start
            end
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
      autoload :WaitForState, action_root.join('wait_for_state')
      autoload :ReadGuestIP, action_root.join('read_guest_ip')
      autoload :ShareFolders, action_root.join('share_folders')
    end
  end
end
