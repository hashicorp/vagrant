# This file contains all of the internal errors in Vagrant's core
# commands, actions, etc.

module Vagrant
  # This module contains all of the internal errors in Vagrant's core.
  # These errors are _expected_ errors and as such don't typically represent
  # bugs in Vagrant itself. These are meant as a way to detect errors and
  # display them in a user-friendly way.
  #
  # # Defining a new Error
  #
  # To define a new error, inherit from {VagrantError}, which lets Vagrant
  # know that this is an expected error, and also gives you some helpers for
  # providing exit codes and error messages. An example is shown below, then
  # it is explained:
  #
  #     class MyError < Vagrant::Errors::VagrantError
  #       error_key "my_error"
  #     end
  #
  # This creates an error with an I18n error key of "my_error." {VagrantError}
  # uses I18n to look up error messages, in the "vagrant.errors" namespace. So
  # in the above, the error message would be the translation of "vagrant.errors.my_error"
  #
  # If you don't want to use I18n, you can override the {#initialize} method and
  # set your own error message.
  #
  # # Raising an Error
  #
  # To raise an error, it is nothing special, just raise it like any normal
  # exception:
  #
  #     raise MyError.new
  #
  # Eventually this exception will bubble out to the `vagrant` binary which
  # will show a nice error message. And if it is raised in the middle of a
  # middleware sequence, then {Action::Warden} will catch it and begin the
  # recovery process prior to exiting.
  module Errors
    # Main superclass of any errors in Vagrant. This provides some
    # convenience methods for setting the status code and error key.
    # The status code is used by the `vagrant` executable as the
    # error code, and the error key is used as a default message from
    # I18n.
    class VagrantError < StandardError
      def self.error_key(key=nil, namespace=nil)
        define_method(:error_key) { key }
        error_namespace(namespace) if namespace
      end

      def self.error_namespace(namespace)
        define_method(:error_namespace) { namespace }
      end

      def initialize(message=nil, *args)
        message = { :_key => message } if message && !message.is_a?(Hash)
        message = { :_key => error_key, :_namespace => error_namespace }.merge(message || {})
        message = translate_error(message)

        super
      end

      # The default error namespace which is used for the error key.
      # This can be overridden here or by calling the "error_namespace"
      # class method.
      def error_namespace; "vagrant.errors"; end

      # The key for the error message. This should be set using the
      # {error_key} method but can be overridden here if needed.
      def error_key; nil; end

      # This is the exit code that should be used when exiting from
      # this exception.
      #
      # @return [Integer]
      def status_code; 1; end

      protected

      def translate_error(opts)
        return nil if !opts[:_key]
        I18n.t("#{opts[:_namespace]}.#{opts[:_key]}", opts)
      end
    end

    class ActiveMachineWithDifferentProvider < VagrantError
      error_key(:active_machine_with_different_provider)
    end

    class AnsibleFailed < VagrantError
      error_key(:ansible_failed)
    end

    class AnsiblePlaybookAppNotFound < VagrantError
      error_key(:ansible_playbook_app_not_found)
    end

    class BaseVMNotFound < VagrantError
      error_key(:base_vm_not_found)
    end

    class BatchMultiError < VagrantError
      error_key(:batch_multi_error)
    end

    class BoxAlreadyExists < VagrantError
      error_key(:already_exists, "vagrant.actions.box.unpackage")
    end

    class BoxConfigChangingBox < VagrantError
      error_key(:box_config_changing_box)
    end

    class BoxMetadataFileNotFound < VagrantError
      error_key(:box_metadata_file_not_found)
    end

    class BoxNotFound < VagrantError
      error_key(:box_not_found)
    end

    class BoxNotSpecified < VagrantError
      error_key(:not_specified, "vagrant.actions.vm.check_box")
    end

    class BoxProviderDoesntMatch < VagrantError
      error_key(:box_provider_doesnt_match)
    end

    class BoxSpecifiedDoesntExist < VagrantError
      error_key(:does_not_exist, "vagrant.actions.vm.check_box")
    end

    class BoxUnpackageFailure < VagrantError
      error_key(:untar_failure, "vagrant.actions.box.unpackage")
    end

    class BoxUpgradeRequired < VagrantError
      error_key(:box_upgrade_required)
    end

    class BoxVerificationFailed < VagrantError
      error_key(:failed, "vagrant.actions.box.verify")
    end

    class CFEngineBootstrapFailed < VagrantError
      error_key(:cfengine_bootstrap_failed)
    end

    class CFEngineCantAutodetectIP < VagrantError
      error_key(:cfengine_cant_autodetect_ip)
    end

    class CFEngineInstallFailed < VagrantError
      error_key(:cfengine_install_failed)
    end

    class CFEngineNotInstalled < VagrantError
      error_key(:cfengine_not_installed)
    end

    class CLIInvalidUsage < VagrantError
      error_key(:cli_invalid_usage)
    end

    class CLIInvalidOptions < VagrantError
      error_key(:cli_invalid_options)
    end

    class CommandUnavailable < VagrantError
      error_key(:command_unavailable)
    end

    class CommandUnavailableWindows < CommandUnavailable
      error_key(:command_unavailable_windows)
    end

    class ConfigInvalid < VagrantError
      error_key(:config_invalid)
    end

    class ConfigUpgradeErrors < VagrantError
      error_key(:config_upgrade_errors)
    end

    class CopyPrivateKeyFailed < VagrantError
      error_key(:copy_private_key_failed)
    end

    class DarwinNFSMountFailed < VagrantError
      error_key(:darwin_nfs_mount_failed)
    end

    class DestroyRequiresForce < VagrantError
      error_key(:destroy_requires_force)
    end

    class DotfileIsDirectory < VagrantError
      error_key(:dotfile_is_directory)
    end

    class DotfileUpgradeJSONError < VagrantError
      error_key(:dotfile_upgrade_json_error)
    end

    class DownloaderError < VagrantError
      error_key(:downloader_error)
    end

    class DownloaderInterrupted < DownloaderError
      error_key(:downloader_interrupted)
    end

    class DownloaderFileDoesntExist < VagrantError
      error_key(:file_missing, "vagrant.downloaders.file")
    end

    class DownloaderHTTPConnectReset < VagrantError
      error_key(:connection_reset, "vagrant.downloaders.http")
    end

    class DownloaderHTTPConnectTimeout < VagrantError
      error_key(:connection_timeout, "vagrant.downloaders.http")
    end

    class DownloaderHTTPSocketError < VagrantError
      error_key(:socket_error, "vagrant.downloaders.http")
    end

    class DownloaderHTTPStatusError < VagrantError
      error_key(:status_error, "vagrant.downloaders.http")
    end

    class EnvironmentNonExistentCWD < VagrantError
      error_key(:environment_non_existent_cwd)
    end

    class EnvironmentLockedError < VagrantError
      error_key(:environment_locked)
    end

    class GemCommandInBundler < VagrantError
      error_key(:gem_command_in_bundler)
    end

    class HomeDirectoryMigrationFailed < VagrantError
      error_key(:home_dir_migration_failed)
    end

    class HomeDirectoryNotAccessible < VagrantError
      error_key(:home_dir_not_accessible)
    end

    class ForwardPortAdapterNotFound < VagrantError
      error_key(:forward_port_adapter_not_found)
    end

    class ForwardPortAutolistEmpty < VagrantError
      error_key(:auto_empty, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortCollision < VagrantError
      error_key(:collision_error, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortCollisionResume < VagrantError
      error_key(:port_collision_resume)
    end

    class GuestCapabilityInvalid < VagrantError
      error_key(:guest_capability_invalid)
    end

    class GuestCapabilityNotFound < VagrantError
      error_key(:guest_capability_not_found)
    end

    class GuestNotDetected < VagrantError
      error_key(:guest_not_detected)
    end

    class LinuxMountFailed < VagrantError
      error_key(:linux_mount_failed)
    end

    class LinuxNFSMountFailed < VagrantError
      error_key(:linux_nfs_mount_failed)
    end

    class LinuxShellExpandFailed < VagrantError
      error_key(:linux_shell_expand_failed)
    end

    class LocalDataDirectoryNotAccessible < VagrantError
      error_key(:local_data_dir_not_accessible)
    end

    class MachineGuestNotReady < VagrantError
      error_key(:machine_guest_not_ready)
    end

    class MachineNotFound < VagrantError
      error_key(:machine_not_found)
    end

    class MachineStateInvalid < VagrantError
      error_key(:machine_state_invalid)
    end

    class MultiVMEnvironmentRequired < VagrantError
      error_key(:multi_vm_required)
    end

    class MultiVMTargetRequired < VagrantError
      error_key(:multi_vm_target_required)
    end

    class NetworkAdapterCollision < VagrantError
      error_key(:adapter_collision, "vagrant.actions.vm.network")
    end

    class NetworkCollision < VagrantError
      error_key(:collides, "vagrant.actions.vm.host_only_network")
    end

    class NetworkNoAdapters < VagrantError
      error_key(:no_adapters, "vagrant.actions.vm.network")
    end

    class NetworkDHCPAlreadyAttached < VagrantError
      error_key(:dhcp_already_attached, "vagrant.actions.vm.network")
    end

    class NetworkNotFound < VagrantError
      error_key(:not_found, "vagrant.actions.vm.host_only_network")
    end

    class NFSCantReadExports < VagrantError
      error_key(:nfs_cant_read_exports)
    end

    class NFSNoGuestIP < VagrantError
      error_key(:nfs_no_guest_ip)
    end

    class NFSNoHostIP < VagrantError
      error_key(:nfs_no_host_ip)
    end

    class NFSNoHostonlyNetwork < VagrantError
      error_key(:nfs_no_hostonly_network)
    end

    class NoEnvironmentError < VagrantError
      error_key(:no_env)
    end

    class PackageIncludeMissing < VagrantError
      error_key(:include_file_missing, "vagrant.actions.general.package")
    end

    class PackageOutputDirectory < VagrantError
      error_key(:output_is_directory, "vagrant.actions.general.package")
    end

    class PackageOutputExists < VagrantError
      error_key(:output_exists, "vagrant.actions.general.package")
    end

    class PackageRequiresDirectory < VagrantError
      error_key(:requires_directory, "vagrant.actions.general.package")
    end

    class PersistDotfileExists < VagrantError
      error_key(:dotfile_error, "vagrant.actions.vm.persist")
    end

    class ProviderNotFound < VagrantError
      error_key(:provider_not_found)
    end

    class ProvisionerFlagInvalid < VagrantError
      error_key(:provisioner_flag_invalid)
    end

    class PluginGemError < VagrantError
      error_key(:plugin_gem_error)
    end

    class PluginInstallBadEntryPoint < VagrantError
      error_key(:plugin_install_bad_entry_point)
    end

    class PluginInstallLicenseNotFound < VagrantError
      error_key(:plugin_install_license_not_found)
    end

    class PluginInstallNotFound < VagrantError
      error_key(:plugin_install_not_found)
    end

    class PluginLoadError < VagrantError
      error_key(:plugin_load_error)
    end

    class PluginLoadFailed < VagrantError
      error_key(:plugin_load_failed)
    end

    class PluginLoadFailedWithOutput < VagrantError
      error_key(:plugin_load_failed_with_output)
    end

    class PluginNotFound < VagrantError
      error_key(:plugin_not_found)
    end

    class PluginNotInstalled < VagrantError
      error_key(:plugin_not_installed)
    end

    class SCPPermissionDenied < VagrantError
      error_key(:scp_permission_denied)
    end

    class SCPUnavailable < VagrantError
      error_key(:scp_unavailable)
    end

    class SharedFolderCreateFailed < VagrantError
      error_key(:shared_folder_create_failed)
    end

    class SSHAuthenticationFailed < VagrantError
      error_key(:ssh_authentication_failed)
    end

    class SSHConnectEACCES < VagrantError
      error_key(:ssh_connect_eacces)
    end

    class SSHConnectionRefused < VagrantError
      error_key(:ssh_connection_refused)
    end

    class SSHConnectionReset < VagrantError
      error_key(:ssh_connection_reset)
    end

    class SSHConnectionTimeout < VagrantError
      error_key(:ssh_connection_timeout)
    end

    class SSHDisconnected < VagrantError
      error_key(:ssh_disconnected)
    end

    class SSHHostDown < VagrantError
      error_key(:ssh_host_down)
    end

    class SSHIsPuttyLink < VagrantError
      error_key(:ssh_is_putty_link)
    end

    class SSHKeyBadOwner < VagrantError
      error_key(:ssh_key_bad_owner)
    end

    class SSHKeyBadPermissions < VagrantError
      error_key(:ssh_key_bad_permissions)
    end

    class SSHKeyTypeNotSupported < VagrantError
      error_key(:ssh_key_type_not_supported)
    end

    class SSHNoRoute < VagrantError
      error_key(:ssh_no_route)
    end

    class SSHNotReady < VagrantError
      error_key(:ssh_not_ready)
    end

    class SSHPortNotDetected < VagrantError
      error_key(:ssh_port_not_detected)
    end

    class SSHUnavailable < VagrantError
      error_key(:ssh_unavailable)
    end

    class SSHUnavailableWindows < VagrantError
      error_key(:ssh_unavailable_windows)
    end

    class UIExpectsTTY < VagrantError
      error_key(:ui_expects_tty)
    end

    class UnimplementedProviderAction < VagrantError
      error_key(:unimplemented_provider_action)
    end

    class VagrantInterrupt < VagrantError
      error_key(:interrupted)
    end

    class VagrantfileExistsError < VagrantError
      error_key(:vagrantfile_exists)
    end

    class VagrantfileLoadError < VagrantError
      error_key(:vagrantfile_load_error)
    end

    class VagrantfileSyntaxError < VagrantError
      error_key(:vagrantfile_syntax_error)
    end

    class VBoxManageError < VagrantError
      error_key(:vboxmanage_error)
    end

    class VBoxManageNotFoundError < VagrantError
      error_key(:vboxmanage_not_found_error)
    end

    class VirtualBoxBrokenVersion040214 < VagrantError
      error_key(:virtualbox_broken_version_040214)
    end

    class VirtualBoxInvalidVersion < VagrantError
      error_key(:virtualbox_invalid_version)
    end

    class VirtualBoxNoRoomForHighLevelNetwork < VagrantError
      error_key(:virtualbox_no_room_for_high_level_network)
    end

    class VirtualBoxNotDetected < VagrantError
      error_key(:virtualbox_not_detected)
    end

    class VirtualBoxKernelModuleNotLoaded < VagrantError
      error_key(:virtualbox_kernel_module_not_loaded)
    end

    class VirtualBoxInstallIncomplete < VagrantError
      error_key(:virtualbox_install_incomplete)
    end

    class VMBaseMacNotSpecified < VagrantError
      error_key(:no_base_mac, "vagrant.actions.vm.match_mac")
    end

    class VMBootBadState < VagrantError
      error_key(:boot_bad_state)
    end

    class VMBootTimeout < VagrantError
      error_key(:boot_timeout)
    end

    class VMCustomizationFailed < VagrantError
      error_key(:failure, "vagrant.actions.vm.customize")
    end

    class VMFailedToBoot < VagrantError
      error_key(:failed_to_boot, "vagrant.actions.vm.boot")
    end

    class VMFailedToRun < VagrantError
      error_key(:failed_to_run, "vagrant.actions.vm.boot")
    end

    class VMGuestError < VagrantError
      error_namespace("vagrant.errors.guest")
    end

    class VMImportFailure < VagrantError
      error_key(:failure, "vagrant.actions.vm.import")
    end

    class VMInaccessible < VagrantError
      error_key(:vm_inaccessible)
    end

    class VMNameExists < VagrantError
      error_key(:vm_name_exists)
    end

    class VMNoMatchError < VagrantError
      error_key(:vm_no_match)
    end

    class VMNotCreatedError < VagrantError
      error_key(:vm_creation_required)
    end

    class VMNotFoundError < VagrantError
      error_key(:vm_not_found)
    end

    class VMNotRunningError < VagrantError
      error_key(:vm_not_running)
    end

    class VMPowerOffToPackage < VagrantError
      error_key(:power_off, "vagrant.actions.vm.export")
    end
  end
end
