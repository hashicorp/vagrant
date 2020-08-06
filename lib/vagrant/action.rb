require 'vagrant/action/builder'

module Vagrant
  module Action
    autoload :Hook,        'vagrant/action/hook'
    autoload :Runner,      'vagrant/action/runner'
    autoload :Warden,      'vagrant/action/warden'

    # Builtin contains middleware classes that are shipped with Vagrant-core
    # and are thus available to all plugins as a "standard library" of sorts.
    module Builtin
      autoload :BoxAdd,    "vagrant/action/builtin/box_add"
      autoload :BoxCheckOutdated, "vagrant/action/builtin/box_check_outdated"
      autoload :BoxRemove, "vagrant/action/builtin/box_remove"
      autoload :Call,    "vagrant/action/builtin/call"
      autoload :CleanupDisks, "vagrant/action/builtin/cleanup_disks"
      autoload :CloudInitSetup, "vagrant/action/builtin/cloud_init_setup"
      autoload :CloudInitWait, "vagrant/action/builtin/cloud_init_wait"
      autoload :Confirm, "vagrant/action/builtin/confirm"
      autoload :ConfigValidate, "vagrant/action/builtin/config_validate"
      autoload :Delayed, "vagrant/action/builtin/delayed"
      autoload :DestroyConfirm, "vagrant/action/builtin/destroy_confirm"
      autoload :Disk, "vagrant/action/builtin/disk"
      autoload :EnvSet,  "vagrant/action/builtin/env_set"
      autoload :GracefulHalt, "vagrant/action/builtin/graceful_halt"
      autoload :HandleBox, "vagrant/action/builtin/handle_box"
      autoload :HandleBoxUrl, "vagrant/action/builtin/handle_box_url"
      autoload :HandleForwardedPortCollisions, "vagrant/action/builtin/handle_forwarded_port_collisions"
      autoload :HasProvisioner, "vagrant/action/builtin/has_provisioner"
      autoload :IsEnvSet, "vagrant/action/builtin/is_env_set"
      autoload :IsState, "vagrant/action/builtin/is_state"
      autoload :Lock, "vagrant/action/builtin/lock"
      autoload :Message, "vagrant/action/builtin/message"
      autoload :PrepareClone, "vagrant/action/builtin/prepare_clone"
      autoload :Provision, "vagrant/action/builtin/provision"
      autoload :ProvisionerCleanup, "vagrant/action/builtin/provisioner_cleanup"
      autoload :SetHostname, "vagrant/action/builtin/set_hostname"
      autoload :SSHExec, "vagrant/action/builtin/ssh_exec"
      autoload :SSHRun,  "vagrant/action/builtin/ssh_run"
      autoload :SyncedFolders, "vagrant/action/builtin/synced_folders"
      autoload :SyncedFolderCleanup, "vagrant/action/builtin/synced_folder_cleanup"
      autoload :Trigger, "vagrant/action/builtin/trigger"
      autoload :WaitForCommunicator, "vagrant/action/builtin/wait_for_communicator"
    end

    module General
      autoload :Package, 'vagrant/action/general/package'
      autoload :PackageSetupFiles, 'vagrant/action/general/package_setup_files'
      autoload :PackageSetupFolders, 'vagrant/action/general/package_setup_folders'
    end

    # This is the action that will add a box from a URL. This middleware
    # sequence is built-in to Vagrant. Plugins can hook into this like any
    # other middleware sequence. This is particularly useful for provider
    # plugins, which can hook in to do things like verification of boxes
    # that are downloaded.
    def self.action_box_add
      Builder.new.tap do |b|
        b.use Builtin::BoxAdd
      end
    end

    # This actions checks if a box is outdated in a given Vagrant
    # environment for a single machine.
    def self.action_box_outdated
      Builder.new.tap do |b|
        b.use Builtin::BoxCheckOutdated
      end
    end

    # This is the action that will remove a box given a name (and optionally
    # a provider). This middleware sequence is built-in to Vagrant. Plugins
    # can hook into this like any other middleware sequence.
    def self.action_box_remove
      Builder.new.tap do |b|
        b.use Builtin::BoxRemove
      end
    end
  end
end
