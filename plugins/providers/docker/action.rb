module VagrantPlugins
  module DockerProvider
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action brings the "machine" up from nothing, including creating the
      # container, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate

          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use HandleBox
            end
          end

          b.use HostMachine

          # Yeah, this is supposed to be here twice (once more above). This
          # catches the case when the container was supposed to be created,
          # but the host state was unknown, and now we know its not actually
          # created.
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use HandleBox
            end
          end

          b.use action_start
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, IsState, :running do |env2, b3|
              if !env2[:result]
                b3.use Message, I18n.t("docker_provider.messages.not_running")
                next
              end

              b3.use Call, HasSSH do |env3, b4|
                if env3[:result]
                  b4.use Provision
                else
                  b4.use Message,
                    I18n.t("docker_provider.messages.provision_no_ssh"),
                    post: true
                end
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :host_state_unknown do |env, b2|
            if env[:result]
              b2.use HostMachine
            end
          end

          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, HasSSH do |env2, b3|
              if !env2[:result]
                b3.use Stop
                next
              end

              b3.use Call, GracefulHalt, :stopped, :running do |env3, b4|
                if !env3[:result]
                  b4.use Stop
                end
              end
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :host_state_unknown do |env, b2|
            if env[:result]
              b2.use HostMachine
            end
          end

          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use ConfigValidate
                b3.use EnvSet, :force_halt => true
                b3.use action_halt
                b3.use HostMachineSyncFoldersDisable
                b3.use Destroy
                b3.use ProvisionerCleanup
              else
                b3.use Message, I18n.t("docker_provider.messages.will_not_destroy")
              end
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, IsState, :running do |env2, b3|
              if !env2[:result]
                b3.use Message, I18n.t("docker_provider.messages.not_running")
                next
              end

              b3.use PrepareSSH
              b3.use SSHExec
            end
          end
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, IsState, :running do |env2, b3|
              if !env2[:result]
                raise Vagrant::Errors::VMNotRunningError
              end

              b3.use SSHRun
            end
          end
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :running do |env, b2|
            # If the container is running, then our work here is done, exit
            next if env[:result]

            b2.use Call, HasSSH do |env2, b3|
              if env2[:result]
                b3.use Provision
              else
                b3.use Message,
                  I18n.t("docker_provider.messages.provision_no_ssh"),
                  post: true
              end
            end

            # We only want to actually sync folder differences if
            # we're not created.
            b2.use Call, IsState, :not_created do |env2, b3|
              if !env2[:result]
                b3.use EnvSet, host_machine_sync_folders: false
              end
            end

            b2.use HostMachineSyncFolders
            b2.use PrepareNFSValidIds
            b2.use SyncedFolderCleanup
            b2.use PrepareNFSSettings

            # If the VM is NOT created yet, then do some setup steps
            # necessary for creating it.
            b2.use Call, IsState, :not_created do |env2, b3|
              if env2[:result]
                b3.use EnvSet, port_collision_repair: true
                b3.use HostMachinePortWarning
                b3.use HostMachinePortChecker
                b3.use HandleForwardedPortCollisions
                b3.use SyncedFolders
                b3.use Create
                b3.use WaitForRunning
              else
                b3.use CompareSyncedFolders
              end
            end

            b2.use Start
            b2.use WaitForRunning

            b2.use Call, HasSSH do |env2, b3|
              if env2[:result]
                b3.use WaitForCommunicator
              end
            end
          end
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :CompareSyncedFolders, action_root.join("compare_synced_folders")
      autoload :Create, action_root.join("create")
      autoload :Destroy, action_root.join("destroy")
      autoload :HasSSH, action_root.join("has_ssh")
      autoload :HostMachine, action_root.join("host_machine")
      autoload :HostMachinePortChecker, action_root.join("host_machine_port_checker")
      autoload :HostMachinePortWarning, action_root.join("host_machine_port_warning")
      autoload :HostMachineRequired, action_root.join("host_machine_required")
      autoload :HostMachineSyncFolders, action_root.join("host_machine_sync_folders")
      autoload :HostMachineSyncFoldersDisable, action_root.join("host_machine_sync_folders_disable")
      autoload :PrepareSSH, action_root.join("prepare_ssh")
      autoload :Stop, action_root.join("stop")
      autoload :PrepareNFSValidIds, action_root.join("prepare_nfs_valid_ids")
      autoload :PrepareNFSSettings, action_root.join("prepare_nfs_settings")
      autoload :Start, action_root.join("start")
      autoload :WaitForRunning, action_root.join("wait_for_running")
    end
  end
end
