module VagrantPlugins
  module DockerProvider
    module Action
      # Include the built-in modules so we can use them as top-level things.
      include Vagrant::Action::Builtin

      # This action starts another container just like the real one running
      # but only for the purpose of running a single command rather than
      # to exist long-running.
      def self.action_run_command
        Vagrant::Action::Builder.new.tap do |b|
          # We just call the "up" action. We create a separate action
          # to hold this though in case we modify it in the future, and
          # so that we can switch on the "machine_action" env var.
          b.use action_up
        end
      end

      # This action brings the "machine" up from nothing, including creating the
      # container, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use HandleBox
            end
          end

          b.use ConfigValidate
          b.use HostMachine

          # Yeah, this is supposed to be here twice (once more above). This
          # catches the case when the container was supposed to be created,
          # but the host state was unknown, and now we know its not actually
          # created.
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use HandleBox
              b2.use DestroyBuildImage
            end
          end

          b.use action_start
        end
      end

      def self.action_package
        lambda do |env|
          raise Errors::PackageNotSupported
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

            b2.use Stop
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsState, :not_created do |env, b2|
            if env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use action_halt

            b2.use Call, IsBuild do |env2, b3|
              if env2[:result]
                b3.use EnvSet, force_halt: true
                b3.use action_halt
                b3.use HostMachineSyncFoldersDisable
                b3.use Destroy
                b3.use ProvisionerCleanup
              end
            end

            b2.use action_start
          end
        end
      end

      # This is the action that is primarily responsible for completely
      # freeing the resources of the underlying virtual machine.
      def self.action_destroy
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsHostMachineCreated do |env, b2|
            if !env[:result]
              b2.use Message, I18n.t("docker_provider.messages.not_created")
              next
            end

            b2.use Call, IsState, :host_state_unknown do |env2, b3|
              if env2[:result]
                b3.use HostMachine
              end
            end

            b2.use Call, IsState, :not_created do |env2, b3|
              if env2[:result]
                b3.use Message,
                  I18n.t("docker_provider.messages.not_created")
                next
              end

              b3.use Call, DestroyConfirm do |env3, b4|
                if env3[:result]
                  b4.use ConfigValidate
                  b4.use ProvisionerCleanup, :before
                  b4.use EnvSet, force_halt: true
                  b4.use action_halt
                  b4.use HostMachineSyncFoldersDisable
                  b4.use Destroy
                  b4.use DestroyBuildImage
                else
                  b4.use Message,
                    I18n.t("docker_provider.messages.will_not_destroy")
                end
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
              raise Errors::ContainerNotCreatedError
            end

            b2.use Call, IsState, :running do |env2, b3|
              if !env2[:result]
                raise Errors::ContainerNotRunningError
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
              raise Errors::ContainerNotCreatedError
            end

            b2.use Call, IsState, :running do |env2, b3|
              if !env2[:result]
                raise Errors::ContainerNotRunningError
              end

              b3.use SSHRun
            end
          end
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, IsState, :running do |env, b2|
            if env[:machine_action] != :run_command
              b2.use Call, HasSSH do |env2, b3|
                if env2[:result]
                  b3.use Provision
                else
                  b3.use Message,
                    I18n.t("docker_provider.messages.provision_no_ssh"),
                    post: true
                end
              end
            end

            # If the container is running and we're doing a run, we're done
            next if env[:result] && env[:machine_action] != :run_command

            b2.use Call, IsState, :not_created do |env2, b3|
              if env2[:result]
                # First time making this thing, set to the "preparing" state
                b3.use InitState
              else
                b3.use EnvSet, host_machine_sync_folders: false
              end
            end

            b2.use HostMachineBuildDir
            b2.use HostMachineSyncFolders
            b2.use PrepareNFSValidIds
            b2.use SyncedFolderCleanup
            b2.use PrepareNFSSettings
            b2.use Login
            b2.use Build

            if env[:machine_action] != :run_command
              # If the container is NOT created yet, then do some setup steps
              # necessary for creating it.
              b2.use Call, IsState, :preparing do |env2, b3|
                if env2[:result]
                  b3.use EnvSet, port_collision_repair: true
                  b3.use HostMachinePortWarning
                  b3.use HostMachinePortChecker
                  b3.use HandleForwardedPortCollisions
                  b3.use SyncedFolders
                  b3.use ForwardedPorts
                  b3.use Pull
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
            else
              # We're in a run command, so we do things a bit differently.
              b2.use SyncedFolders
              b2.use Create
            end
          end
        end
      end

      def self.action_suspend
        lambda do |env|
          raise Errors::SuspendNotSupported
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :Build, action_root.join("build")
      autoload :CompareSyncedFolders, action_root.join("compare_synced_folders")
      autoload :Create, action_root.join("create")
      autoload :Destroy, action_root.join("destroy")
      autoload :DestroyBuildImage, action_root.join("destroy_build_image")
      autoload :ForwardedPorts, action_root.join("forwarded_ports")
      autoload :HasSSH, action_root.join("has_ssh")
      autoload :HostMachine, action_root.join("host_machine")
      autoload :HostMachineBuildDir, action_root.join("host_machine_build_dir")
      autoload :HostMachinePortChecker, action_root.join("host_machine_port_checker")
      autoload :HostMachinePortWarning, action_root.join("host_machine_port_warning")
      autoload :HostMachineRequired, action_root.join("host_machine_required")
      autoload :HostMachineSyncFolders, action_root.join("host_machine_sync_folders")
      autoload :HostMachineSyncFoldersDisable, action_root.join("host_machine_sync_folders_disable")
      autoload :InitState, action_root.join("init_state")
      autoload :IsBuild, action_root.join("is_build")
      autoload :IsHostMachineCreated, action_root.join("is_host_machine_created")
      autoload :Login, action_root.join("login")
      autoload :Pull, action_root.join("pull")
      autoload :PrepareSSH, action_root.join("prepare_ssh")
      autoload :Stop, action_root.join("stop")
      autoload :PrepareNFSValidIds, action_root.join("prepare_nfs_valid_ids")
      autoload :PrepareNFSSettings, action_root.join("prepare_nfs_settings")
      autoload :Start, action_root.join("start")
      autoload :WaitForRunning, action_root.join("wait_for_running")
    end
  end
end
