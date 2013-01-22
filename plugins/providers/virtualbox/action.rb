require "vagrant/action/builder"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      autoload :Boot, File.expand_path("../action/boot", __FILE__)
      autoload :CheckAccessible, File.expand_path("../action/check_accessible", __FILE__)
      autoload :CheckBox, File.expand_path("../action/check_box", __FILE__)
      autoload :CheckCreated, File.expand_path("../action/check_created", __FILE__)
      autoload :CheckGuestAdditions, File.expand_path("../action/check_guest_additions", __FILE__)
      autoload :CheckPortCollisions, File.expand_path("../action/check_port_collisions", __FILE__)
      autoload :CheckRunning, File.expand_path("../action/check_running", __FILE__)
      autoload :CheckVirtualbox, File.expand_path("../action/check_virtualbox", __FILE__)
      autoload :CleanMachineFolder, File.expand_path("../action/clean_machine_folder", __FILE__)
      autoload :ClearForwardedPorts, File.expand_path("../action/clear_forwarded_ports", __FILE__)
      autoload :ClearNetworkInterfaces, File.expand_path("../action/clear_network_interfaces", __FILE__)
      autoload :ClearSharedFolders, File.expand_path("../action/clear_shared_folders", __FILE__)
      autoload :Created, File.expand_path("../action/created", __FILE__)
      autoload :Customize, File.expand_path("../action/customize", __FILE__)
      autoload :DefaultName, File.expand_path("../action/default_name", __FILE__)
      autoload :Destroy, File.expand_path("../action/destroy", __FILE__)
      autoload :DestroyConfirm, File.expand_path("../action/destroy_confirm", __FILE__)
      autoload :DestroyUnusedNetworkInterfaces, File.expand_path("../action/destroy_unused_network_interfaces", __FILE__)
      autoload :DiscardState, File.expand_path("../action/discard_state", __FILE__)
      autoload :Export, File.expand_path("../action/export", __FILE__)
      autoload :ForcedHalt, File.expand_path("../action/forced_halt", __FILE__)
      autoload :ForwardPorts, File.expand_path("../action/forward_ports", __FILE__)
      autoload :HostName, File.expand_path("../action/host_name", __FILE__)
      autoload :Import, File.expand_path("../action/import", __FILE__)
      autoload :IsRunning, File.expand_path("../action/is_running", __FILE__)
      autoload :IsSaved, File.expand_path("../action/is_saved", __FILE__)
      autoload :MatchMACAddress, File.expand_path("../action/match_mac_address", __FILE__)
      autoload :MessageNotCreated, File.expand_path("../action/message_not_created", __FILE__)
      autoload :MessageNotRunning, File.expand_path("../action/message_not_running", __FILE__)
      autoload :MessageWillNotDestroy, File.expand_path("../action/message_will_not_destroy", __FILE__)
      autoload :Network, File.expand_path("../action/network", __FILE__)
      autoload :NFS, File.expand_path("../action/nfs", __FILE__)
      autoload :Package, File.expand_path("../action/package", __FILE__)
      autoload :PackageVagrantfile, File.expand_path("../action/package_vagrantfile", __FILE__)
      autoload :PruneNFSExports, File.expand_path("../action/prune_nfs_exports", __FILE__)
      autoload :Resume, File.expand_path("../action/resume", __FILE__)
      autoload :SaneDefaults, File.expand_path("../action/sane_defaults", __FILE__)
      autoload :SetupPackageFiles, File.expand_path("../action/setup_package_files", __FILE__)
      autoload :ShareFolders, File.expand_path("../action/share_folders", __FILE__)
      autoload :Suspend, File.expand_path("../action/suspend", __FILE__)

      # Include the built-in modules so that we can use them as top-level
      # things.
      include Vagrant::Action::Builtin

      # This action boots the VM, assuming the VM is in a state that requires
      # a bootup (i.e. not saved).
      def self.action_boot
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckAccessible
          b.use CleanMachineFolder
          b.use ClearForwardedPorts
          b.use EnvSet, :port_collision_handler => :correct
          b.use Provision
          b.use CheckPortCollisions
          b.use PruneNFSExports
          b.use NFS
          b.use ClearSharedFolders
          b.use ShareFolders
          b.use ClearNetworkInterfaces
          b.use Network
          b.use ForwardPorts
          b.use HostName
          b.use SaneDefaults
          b.use Customize
          b.use Boot
        end
      end

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
                b3.use ConfigValidate
                b3.use CheckAccessible
                b3.use EnvSet, :force_halt => true
                b3.use action_halt
                b3.use PruneNFSExports
                b3.use Destroy
                b3.use CleanMachineFolder
                b3.use DestroyUnusedNetworkInterfaces
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
              b2.use Call, GracefulHalt, :poweroff, :running do |env2, b3|
                if !env2[:result]
                  b3.use ForcedHalt
                end
              end
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This action packages the virtual machine into a single box file.
      def self.action_package
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use SetupPackageFiles
            b2.use CheckAccessible
            b2.use action_halt
            b2.use ClearForwardedPorts
            b2.use ClearSharedFolders
            b2.use Export
            b2.use PackageVagrantfile
            b2.use Package
          end
        end
      end

      # This action just runs the provisioners on the machine.
      def self.action_provision
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use ConfigValidate
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use Call, IsRunning do |env2, b3|
              if !env2[:result]
                b3.use MessageNotRunning
                next
              end

              b3.use CheckAccessible
              b3.use Provision
            end
          end
        end
      end

      # This action is responsible for reloading the machine, which
      # brings it down, sucks in new configuration, and brings the
      # machine back up with the new configuration.
      def self.action_reload
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env1, b2|
            if !env1[:result]
              b2.use MessageNotCreated
              next
            end

            b2.use ConfigValidate
            b2.use action_halt
            b2.use action_start
          end
        end
      end

      # This is the action that is primarily responsible for resuming
      # suspended machines.
      def self.action_resume
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use EnvSet, :port_collision_handler => :error
              b2.use CheckPortCollisions
              b2.use Resume
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This is the action that will exec into an SSH shell.
      def self.action_ssh
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHExec
        end
      end

      # This is the action that will run a single SSH command.
      def self.action_ssh_run
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use CheckCreated
          b.use CheckAccessible
          b.use CheckRunning
          b.use SSHRun
        end
      end

      # This action starts a VM, assuming it is already imported and exists.
      # A precondition of this action is that the VM exists.
      def self.action_start
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use ConfigValidate
          b.use Call, IsRunning do |env, b2|
            # If the VM is running, then our work here is done, exit
            next if env[:result]

            b2.use Call, IsSaved do |env2, b3|
              if env2[:result]
                # The VM is saved, so just resume it
                b3.use action_resume
              else
                # The VM is not saved, so we must have to boot it up
                # like normal. Boot!
                b3.use action_boot
              end
            end
          end
        end
      end

      # This is the action that is primarily responsible for suspending
      # the virtual machine.
      def self.action_suspend
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use Call, Created do |env, b2|
            if env[:result]
              b2.use CheckAccessible
              b2.use Suspend
            else
              b2.use MessageNotCreated
            end
          end
        end
      end

      # This action brings the machine up from nothing, including importing
      # the box, configuring metadata, and booting.
      def self.action_up
        Vagrant::Action::Builder.new.tap do |b|
          b.use CheckVirtualbox
          b.use ConfigValidate
          b.use Call, Created do |env, b2|
            # If the VM is NOT created yet, then do the setup steps
            if !env[:result]
              b2.use CheckAccessible
              b2.use CheckBox
              b2.use Import
              b2.use CheckGuestAdditions
              b2.use DefaultName
              b2.use MatchMACAddress
            end
          end
          b.use action_start
        end
      end
    end
  end
end
