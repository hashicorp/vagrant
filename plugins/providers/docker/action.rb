module VagrantPlugins
  module DockerProvider
    module Action
      include Vagrant::Action::Builtin

      # This action brings the "machine" up from nothing, including creating the
      # container, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, Created do |env, b2|
            if !env[:result]
              b2.use HandleBoxUrl
              # TODO: Find out where this fits into the process
              # b2.use EnvSet, :port_collision_repair => true
              # b2.use HandleForwardedPortCollisions
              b2.use Provision
              b2.use PrepareNFSValidIds
              b2.use SyncedFolderCleanup
              b2.use SyncedFolders
              b2.use PrepareNFSSettings
              b2.use ForwardPorts
              # This will actually create and start, but that's fine
              b2.use Create
              b2.use action_boot
            else
              b2.use PrepareNFSValidIds
              b2.use SyncedFolderCleanup
              b2.use SyncedFolders
              b2.use PrepareNFSSettings
              b2.use action_start
            end
          end
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use Message, :not_running
                next
              end

              b3.use Provision
            end
          end
        end
      end

      # This is the action that is primarily responsible for halting
      # the virtual machine, gracefully or by force.
      def self.action_halt
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use Call, GracefulHalt, :stopped, :running do |env2, b3|
                if !env2[:result]
                  b3.use Stop
                end
              end
            else
              b2.use Message, :not_created
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
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
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use Message, :not_created
              next
            end

            b2.use Call, DestroyConfirm do |env2, b3|
              if env2[:result]
                b3.use ConfigValidate
                b3.use EnvSet, :force_halt => true
                b3.use action_halt
                b3.use Destroy
                b3.use ProvisionerCleanup
              else
                b3.use Message, :will_not_destroy
              end
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckRunning
          b.use SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckRunning
          b.use SSHRun
        end
      end

      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use ConfigValidate
          b.use Call, IsRunning do |env, b2|
            # If the container is running, then our work here is done, exit
            next if env[:result]

            b2.use Provision
            b2.use Message, :starting
            b2.use action_boot
          end
        end
      end

      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          # TODO: b.use SetHostname
          b.use Start
          b.use WaitForCommunicator
        end
      end

      # The autoload farm
      action_root = Pathname.new(File.expand_path("../action", __FILE__))
      autoload :CheckRunning, action_root.join("check_running")
      autoload :Created, action_root.join("created")
      autoload :Create, action_root.join("create")
      autoload :Destroy, action_root.join("destroy")
      autoload :ForwardPorts, action_root.join("forward_ports")
      autoload :Stop, action_root.join("stop")
      autoload :Message, action_root.join("message")
      autoload :PrepareNFSValidIds, action_root.join("prepare_nfs_valid_ids")
      autoload :PrepareNFSSettings, action_root.join("prepare_nfs_settings")
      autoload :IsRunning, action_root.join("is_running")
      autoload :Start, action_root.join("start")
    end
  end
end
