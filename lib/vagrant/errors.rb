# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

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
      # This is extra data passed into the message for translation.
      attr_accessor :extra_data

      def self.error_key(key=nil, namespace=nil)
        define_method(:error_key) { key }
        error_namespace(namespace) if namespace
      end

      def self.error_message(message)
        define_method(:error_message) { message }
      end

      def self.error_namespace(namespace)
        define_method(:error_namespace) { namespace }
      end

      def initialize(*args)
        key     = args.shift if args.first.is_a?(Symbol)
        message = args.shift if args.first.is_a?(Hash)
        message ||= {}
        @extra_data    = message.dup
        message[:_key] ||= error_key
        message[:_namespace] ||= error_namespace
        message[:_key] = key if key

        if message[:_key]
          message = translate_error(message)
        else
          message = error_message
        end

        super(message)
      end

      # The error message for this error. This is used if no error_key
      # is specified for a translatable error message.
      def error_message; "No error message"; end

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
        I18n.t("#{opts[:_namespace]}.#{opts[:_key]}", **opts)
      end
    end

    class ActiveMachineWithDifferentProvider < VagrantError
      error_key(:active_machine_with_different_provider)
    end

    class AliasInvalidError < VagrantError
      error_key(:alias_invalid_error)
    end

    class BatchMultiError < VagrantError
      error_key(:batch_multi_error)
    end

    class BoxAddDirectVersion < VagrantError
      error_key(:box_add_direct_version)
    end

    class BoxAddMetadataMultiURL < VagrantError
      error_key(:box_add_metadata_multi_url)
    end

    class BoxAddNameMismatch < VagrantError
      error_key(:box_add_name_mismatch)
    end

    class BoxAddNameRequired < VagrantError
      error_key(:box_add_name_required)
    end

    class BoxAddNoMatchingProvider < VagrantError
      error_key(:box_add_no_matching_provider)
    end

    class BoxAddNoArchitectureSupport < VagrantError
      error_key(:box_add_no_architecture_support)
    end

    class BoxAddNoMatchingArchitecture < VagrantError
      error_key(:box_add_no_matching_architecture)
    end

    class BoxAddNoMatchingProviderVersion < VagrantError
      error_key(:box_add_no_matching_provider_version)
    end

    class BoxAddNoMatchingVersion < VagrantError
      error_key(:box_add_no_matching_version)
    end

    class BoxAddShortNotFound < VagrantError
      error_key(:box_add_short_not_found)
    end

    class BoxAlreadyExists < VagrantError
      error_key(:box_add_exists)
    end

    class BoxChecksumInvalidType < VagrantError
      error_key(:box_checksum_invalid_type)
    end

    class BoxChecksumMismatch < VagrantError
      error_key(:box_checksum_mismatch)
    end

    class BoxConfigChangingBox < VagrantError
      error_key(:box_config_changing_box)
    end

    class BoxFileNotExist < VagrantError
      error_key(:box_file_not_exist)
    end

    class BoxMetadataCorrupted < VagrantError
      error_key(:box_metadata_corrupted)
    end

    class BoxMetadataMissingRequiredFields < VagrantError
      error_key(:box_metadata_missing_required_fields)
    end

    class BoxMetadataDownloadError < VagrantError
      error_key(:box_metadata_download_error)
    end

    class BoxMetadataFileNotFound < VagrantError
      error_key(:box_metadata_file_not_found)
    end

    class BoxMetadataMalformed < VagrantError
      error_key(:box_metadata_malformed)
    end

    class BoxMetadataMalformedVersion < VagrantError
      error_key(:box_metadata_malformed_version)
    end

    class BoxNotFound < VagrantError
      error_key(:box_not_found)
    end

    class BoxNotFoundWithProvider < VagrantError
      error_key(:box_not_found_with_provider)
    end

    class BoxNotFoundWithProviderArchitecture < VagrantError
      error_key(:box_not_found_with_provider_architecture)
    end

    class BoxNotFoundWithProviderAndVersion < VagrantError
      error_key(:box_not_found_with_provider_and_version)
    end

    class BoxProviderDoesntMatch < VagrantError
      error_key(:box_provider_doesnt_match)
    end

    class BoxRemoveNotFound < VagrantError
      error_key(:box_remove_not_found)
    end

    class BoxRemoveArchitectureNotFound < VagrantError
      error_key(:box_remove_architecture_not_found)
    end

    class BoxRemoveProviderNotFound < VagrantError
      error_key(:box_remove_provider_not_found)
    end

    class BoxRemoveVersionNotFound < VagrantError
      error_key(:box_remove_version_not_found)
    end

    class BoxRemoveMultiArchitecture < VagrantError
      error_key(:box_remove_multi_architecture)
    end

    class BoxRemoveMultiProvider < VagrantError
      error_key(:box_remove_multi_provider)
    end

    class BoxRemoveMultiVersion < VagrantError
      error_key(:box_remove_multi_version)
    end

    class BoxServerNotSet < VagrantError
      error_key(:box_server_not_set)
    end

    class BoxUnpackageFailure < VagrantError
      error_key(:untar_failure, "vagrant.actions.box.unpackage")
    end

    class BoxUpdateMultiProvider < VagrantError
      error_key(:box_update_multi_provider)
    end

    class BoxUpdateMultiArchitecture < VagrantError
      error_key(:box_update_multi_architecture)
    end

    class BoxUpdateNoMetadata < VagrantError
      error_key(:box_update_no_metadata)
    end

    class BoxVerificationFailed < VagrantError
      error_key(:failed, "vagrant.actions.box.verify")
    end

    class BoxVersionInvalid < VagrantError
      error_key(:box_version_invalid)
    end

    class BundlerDisabled < VagrantError
      error_key(:bundler_disabled)
    end

    class BundlerError < VagrantError
      error_key(:bundler_error)
    end

    class SourceSpecNotFound < BundlerError
      error_key(:source_spec_not_found)
    end

    class CantReadMACAddresses < VagrantError
      error_key(:cant_read_mac_addresses)
    end

    class CapabilityHostExplicitNotDetected < VagrantError
      error_key(:capability_host_explicit_not_detected)
    end

    class CapabilityHostNotDetected < VagrantError
      error_key(:capability_host_not_detected)
    end

    class CapabilityInvalid < VagrantError
      error_key(:capability_invalid)
    end

    class CapabilityNotFound < VagrantError
      error_key(:capability_not_found)
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

    class CloneNotFound < VagrantError
      error_key(:clone_not_found)
    end

    class CloneMachineNotFound < VagrantError
      error_key(:clone_machine_not_found)
    end

    class CloudInitNotFound < VagrantError
      error_key(:cloud_init_not_found)
    end

    class CloudInitCommandFailed < VagrantError
      error_key(:cloud_init_command_failed)
    end

    class CommandDeprecated < VagrantError
      error_key(:command_deprecated)
    end

    class CommandSuspendAllArgs < VagrantError
      error_key(:command_suspend_all_arguments)
    end

    class CommandUnavailable < VagrantError
      error_key(:command_unavailable)
    end

    class CommandUnavailableWindows < CommandUnavailable
      error_key(:command_unavailable_windows)
    end

    class CommunicatorNotFound < VagrantError
      error_key(:communicator_not_found)
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

    class CorruptMachineIndex < VagrantError
      error_key(:corrupt_machine_index)
    end

    class CreateIsoHostCapNotFound < VagrantError
      error_key(:create_iso_host_cap_not_found)
    end

    class DarwinMountFailed < VagrantError
      error_key(:darwin_mount_failed)
    end

    class DarwinVersionFailed < VagrantError
      error_key(:darwin_version_failed)
    end

    class DestroyRequiresForce < VagrantError
      error_key(:destroy_requires_force)
    end

    class DotfileUpgradeJSONError < VagrantError
      error_key(:dotfile_upgrade_json_error)
    end

    class DownloadAlreadyInProgress < VagrantError
      error_key(:download_already_in_progress_error)
    end

    class DownloaderError < VagrantError
      error_key(:downloader_error)
    end

    class DownloaderInterrupted < DownloaderError
      error_key(:downloader_interrupted)
    end

    class DownloaderChecksumError < VagrantError
      error_key(:downloader_checksum_error)
    end

    class EnvInval < VagrantError
      error_key(:env_inval)
    end

    class EnvironmentNonExistentCWD < VagrantError
      error_key(:environment_non_existent_cwd)
    end

    class EnvironmentLockedError < VagrantError
      error_key(:environment_locked)
    end

    class HomeDirectoryLaterVersion < VagrantError
      error_key(:home_dir_later_version)
    end

    class HomeDirectoryNotAccessible < VagrantError
      error_key(:home_dir_not_accessible)
    end

    class HomeDirectoryUnknownVersion < VagrantError
      error_key(:home_dir_unknown_version)
    end

    class HypervVirtualBoxError < VagrantError
      error_key(:hyperv_virtualbox_error)
    end

    class ForwardPortAdapterNotFound < VagrantError
      error_key(:forward_port_adapter_not_found)
    end

    class ForwardPortAutolistEmpty < VagrantError
      error_key(:auto_empty, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortHostIPNotFound < VagrantError
      error_key(:host_ip_not_found, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortCollision < VagrantError
      error_key(:collision_error, "vagrant.actions.vm.forward_ports")
    end

    class GuestCapabilityInvalid < VagrantError
      error_key(:guest_capability_invalid)
    end

    class GuestCapabilityNotFound < VagrantError
      error_key(:guest_capability_not_found)
    end

    class GuestExplicitNotDetected < VagrantError
      error_key(:guest_explicit_not_detected)
    end

    class GuestNotDetected < VagrantError
      error_key(:guest_not_detected)
    end

    class HostExplicitNotDetected < VagrantError
      error_key(:host_explicit_not_detected)
    end

    class ISOBuildFailed < VagrantError
      error_key(:iso_build_failed)
    end

    class LinuxMountFailed < VagrantError
      error_key(:linux_mount_failed)
    end

    class LinuxRDPClientNotFound < VagrantError
      error_key(:linux_rdp_client_not_found)
    end

    class LocalDataDirectoryNotAccessible < VagrantError
      error_key(:local_data_dir_not_accessible)
    end

    class MachineActionLockedError < VagrantError
      error_key(:machine_action_locked)
    end

    class MachineFolderNotAccessible < VagrantError
      error_key(:machine_folder_not_accessible)
    end

    class MachineGuestNotReady < VagrantError
      error_key(:machine_guest_not_ready)
    end

    class MachineLocked < VagrantError
      error_key(:machine_locked)
    end

    class MachineNotFound < VagrantError
      error_key(:machine_not_found)
    end

    class MachineStateInvalid < VagrantError
      error_key(:machine_state_invalid)
    end

    class MultiVMTargetRequired < VagrantError
      error_key(:multi_vm_target_required)
    end

    class NetplanNoAvailableRenderers < VagrantError
      error_key(:netplan_no_available_renderers)
    end

    class NetSSHException < VagrantError
      error_key(:net_ssh_exception)
    end

    class NetworkCollision < VagrantError
      error_key(:collides, "vagrant.actions.vm.host_only_network")
    end

    class NetworkAddressInvalid < VagrantError
      error_key(:network_address_invalid)
    end

    class NetworkDHCPAlreadyAttached < VagrantError
      error_key(:dhcp_already_attached, "vagrant.actions.vm.network")
    end

    class NetworkNotFound < VagrantError
      error_key(:not_found, "vagrant.actions.vm.host_only_network")
    end

    class NetworkTypeNotSupported < VagrantError
      error_key(:network_type_not_supported)
    end

    class NetworkManagerNotInstalled < VagrantError
      error_key(:network_manager_not_installed)
    end

    class NFSBadExports < VagrantError
      error_key(:nfs_bad_exports)
    end

    class NFSDupePerms < VagrantError
      error_key(:nfs_dupe_permissions)
    end

    class NFSExportsFailed < VagrantError
      error_key(:nfs_exports_failed)
    end

    class NFSCantReadExports < VagrantError
      error_key(:nfs_cant_read_exports)
    end

    class NFSMountFailed < VagrantError
      error_key(:nfs_mount_failed)
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

    class NFSNoValidIds < VagrantError
      error_key(:nfs_no_valid_ids)
    end

    class NFSNotSupported < VagrantError
      error_key(:nfs_not_supported)
    end

    class NFSClientNotInstalledInGuest < VagrantError
      error_key(:nfs_client_not_installed_in_guest)
    end

    class NoDefaultProvider < VagrantError
      error_key(:no_default_provider)
    end

    class NoDefaultSyncedFolderImpl < VagrantError
      error_key(:no_default_synced_folder_impl)
    end

    class NoEnvironmentError < VagrantError
      error_key(:no_env)
    end

    class OscdimgCommandMissingError < VagrantError
      error_key(:oscdimg_command_missing)
    end

    class PackageIncludeMissing < VagrantError
      error_key(:include_file_missing, "vagrant.actions.general.package")
    end

    class PackageIncludeSymlink < VagrantError
      error_key(:package_include_symlink)
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

    class PackageInvalidInfo < VagrantError
      error_key(:package_invalid_info)
    end

    class PowerShellNotFound < VagrantError
      error_key(:powershell_not_found)
    end

    class PowerShellInvalidVersion < VagrantError
      error_key(:powershell_invalid_version)
    end

    class PowerShellError < VagrantError
      error_key(:powershell_error, "vagrant_ps.errors.powershell_error")
    end

    class ProviderCantInstall < VagrantError
      error_key(:provider_cant_install)
    end

    class ProviderChecksumMismatch < VagrantError
      error_key(:provider_checksum_mismatch)
    end

    class ProviderInstallFailed < VagrantError
      error_key(:provider_install_failed)
    end

    class ProviderNotFound < VagrantError
      error_key(:provider_not_found)
    end

    class ProviderNotFoundSuggestion < VagrantError
      error_key(:provider_not_found_suggestion)
    end

    class ProviderNotUsable < VagrantError
      error_key(:provider_not_usable)
    end

    class ProvisionerFlagInvalid < VagrantError
      error_key(:provisioner_flag_invalid)
    end

    class ProvisionerWinRMUnsupported < VagrantError
      error_key(:provisioner_winrm_unsupported)
    end

    class PluginNeedsDeveloperTools < VagrantError
      error_key(:plugin_needs_developer_tools)
    end

    class PluginMissingLibrary < VagrantError
      error_key(:plugin_missing_library)
    end

    class PluginMissingRubyDev < VagrantError
      error_key(:plugin_missing_ruby_dev)
    end

    class PluginGemNotFound < VagrantError
      error_key(:plugin_gem_not_found)
    end

    class PluginInstallLicenseNotFound < VagrantError
      error_key(:plugin_install_license_not_found)
    end

    class PluginInstallFailed < VagrantError
      error_key(:plugin_install_failed)
    end

    class PluginInstallSpace < VagrantError
      error_key(:plugin_install_space)
    end

    class PluginInstallVersionConflict < VagrantError
      error_key(:plugin_install_version_conflict)
    end

    class PluginLoadError < VagrantError
      error_key(:plugin_load_error)
    end

    class PluginNotInstalled < VagrantError
      error_key(:plugin_not_installed)
    end

    class PluginStateFileParseError < VagrantError
      error_key(:plugin_state_file_not_parsable)
    end

    class PluginUninstallSystem < VagrantError
      error_key(:plugin_uninstall_system)
    end

    class PluginInitError < VagrantError
      error_key(:plugin_init_error)
    end

    class PluginSourceError < VagrantError
      error_key(:plugin_source_error)
    end

    class PluginNoLocalError < VagrantError
      error_key(:plugin_no_local_error)
    end

    class PluginMissingLocalError < VagrantError
      error_key(:plugin_missing_local_error)
    end

    class PushesNotDefined < VagrantError
      error_key(:pushes_not_defined)
    end

    class PushStrategyNotDefined < VagrantError
      error_key(:push_strategy_not_defined)
    end

    class PushStrategyNotLoaded < VagrantError
      error_key(:push_strategy_not_loaded)
    end

    class PushStrategyNotProvided < VagrantError
      error_key(:push_strategy_not_provided)
    end

    class RSyncPostCommandError < VagrantError
      error_key(:rsync_post_command_error)
    end

    class RSyncError < VagrantError
      error_key(:rsync_error)
    end

    class RSyncNotFound < VagrantError
      error_key(:rsync_not_found)
    end

    class RSyncNotInstalledInGuest < VagrantError
      error_key(:rsync_not_installed_in_guest)
    end

    class RSyncGuestInstallError < VagrantError
      error_key(:rsync_guest_install_error)
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

    class ShellExpandFailed < VagrantError
      error_key(:shell_expand_failed)
    end

    class SnapshotConflictFailed < VagrantError
      error_key(:snapshot_force)
    end

    class SnapshotNotFound < VagrantError
      error_key(:snapshot_not_found)
    end

    class SnapshotNotSupported < VagrantError
      error_key(:snapshot_not_supported)
    end

    class SSHAuthenticationFailed < VagrantError
      error_key(:ssh_authentication_failed)
    end

    class SSHChannelOpenFail < VagrantError
      error_key(:ssh_channel_open_fail)
    end

    class SSHConnectEACCES < VagrantError
      error_key(:ssh_connect_eacces)
    end

    class SSHConnectionRefused < VagrantError
      error_key(:ssh_connection_refused)
    end

    class SSHConnectionAborted < VagrantError
      error_key(:ssh_connection_aborted)
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

    class SSHInvalidShell< VagrantError
      error_key(:ssh_invalid_shell)
    end

    class SSHInsertKeyUnsupported < VagrantError
      error_key(:ssh_insert_key_unsupported)
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

    class SSHKeyTypeNotSupportedByServer < VagrantError
      error_key(:ssh_key_type_not_supported_by_server)
    end

    class SSHNoExitStatus < VagrantError
      error_key(:ssh_no_exit_status)
    end

    class SSHNoRoute < VagrantError
      error_key(:ssh_no_route)
    end

    class SSHNotReady < VagrantError
      error_key(:ssh_not_ready)
    end

    class SSHRunRequiresKeys < VagrantError
      error_key(:ssh_run_requires_keys)
    end

    class SSHUnavailable < VagrantError
      error_key(:ssh_unavailable)
    end

    class SSHUnavailableWindows < VagrantError
      error_key(:ssh_unavailable_windows)
    end

    class SyncedFolderUnusable < VagrantError
      error_key(:synced_folder_unusable)
    end

    class TriggersBadExitCodes < VagrantError
      error_key(:triggers_bad_exit_codes)
    end

    class TriggersGuestNotExist < VagrantError
      error_key(:triggers_guest_not_exist)
    end

    class TriggersGuestNotRunning < VagrantError
      error_key(:triggers_guest_not_running)
    end

    class TriggersNoBlockGiven < VagrantError
      error_key(:triggers_no_block_given)
    end

    class TriggersNoStageGiven < VagrantError
      error_key(:triggers_no_stage_given)
    end

    class UIExpectsTTY < VagrantError
      error_key(:ui_expects_tty)
    end

    class UnimplementedProviderAction < VagrantError
      error_key(:unimplemented_provider_action)
    end

    class UploadInvalidCompressionType < VagrantError
      error_key(:upload_invalid_compression_type)
    end

    class UploadMissingExtractCapability < VagrantError
      error_key(:upload_missing_extract_capability)
    end

    class UploadMissingTempCapability < VagrantError
      error_key(:upload_missing_temp_capability)
    end

    class UploadSourceMissing < VagrantError
      error_key(:upload_source_missing)
    end

    class UploaderError < VagrantError
      error_key(:uploader_error)
    end

    class UploaderInterrupted < UploaderError
      error_key(:uploader_interrupted)
    end

    class VagrantLocked < VagrantError
      error_key(:vagrant_locked)
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

    class VagrantfileNameError < VagrantError
      error_key(:vagrantfile_name_error)
    end

    class VagrantfileSyntaxError < VagrantError
      error_key(:vagrantfile_syntax_error)
    end

    class VagrantfileTemplateNotFoundError < VagrantError
      error_key(:vagrantfile_template_not_found_error)
    end

    class VagrantfileWriteError < VagrantError
      error_key(:vagrantfile_write_error)
    end

    class VagrantVersionBad < VagrantError
      error_key(:vagrant_version_bad)
    end

    class VBoxManageError < VagrantError
      error_key(:vboxmanage_error)
    end

    class VBoxManageLaunchError < VagrantError
      error_key(:vboxmanage_launch_error)
    end

    class VBoxManageNotFoundError < VagrantError
      error_key(:vboxmanage_not_found_error)
    end

    class VirtualBoxBrokenVersion040214 < VagrantError
      error_key(:virtualbox_broken_version_040214)
    end

    class VirtualBoxConfigNotFound < VagrantError
      error_key(:virtualbox_config_not_found)
    end

    class VirtualBoxDisksDefinedExceedLimit < VagrantError
      error_key(:virtualbox_disks_defined_exceed_limit)
    end

    class VirtualBoxDisksControllerNotFound < VagrantError
      error_key(:virtualbox_disks_controller_not_found)
    end

    class VirtualBoxDisksNoSupportedControllers < VagrantError
      error_key(:virtualbox_disks_no_supported_controllers)
    end

    class VirtualBoxDisksPrimaryNotFound < VagrantError
      error_key(:virtualbox_disks_primary_not_found)
    end

    class VirtualBoxDisksUnsupportedController < VagrantError
      error_key(:virtualbox_disks_unsupported_controller)
    end

    class VirtualBoxGuestPropertyNotFound < VagrantError
      error_key(:virtualbox_guest_property_not_found)
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

    class VirtualBoxMachineFolderNotFound < VagrantError
      error_key(:virtualbox_machine_folder_not_found)
    end

    class VirtualBoxNoName < VagrantError
      error_key(:virtualbox_no_name)
    end

    class VirtualBoxMountFailed < VagrantError
      error_key(:virtualbox_mount_failed)
    end

    class VirtualBoxMountNotSupportedBSD < VagrantError
      error_key(:virtualbox_mount_not_supported_bsd)
    end

    class VirtualBoxNameExists < VagrantError
      error_key(:virtualbox_name_exists)
    end

    class VirtualBoxUserMismatch < VagrantError
      error_key(:virtualbox_user_mismatch)
    end

    class VirtualBoxVersionEmpty < VagrantError
      error_key(:virtualbox_version_empty)
    end

    class VirtualBoxInvalidHostSubnet < VagrantError
      error_key(:virtualbox_invalid_host_subnet)
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

    class VMCloneFailure < VagrantError
      error_key(:failure, "vagrant.actions.vm.clone")
    end

    class VMCreateMasterFailure < VagrantError
      error_key(:failure, "vagrant.actions.vm.clone.create_master")
    end

    class VMCustomizationFailed < VagrantError
      error_key(:failure, "vagrant.actions.vm.customize")
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

    class WinRMInvalidCommunicator < VagrantError
      error_key(:winrm_invalid_communicator)
    end

    class WSLVagrantVersionMismatch < VagrantError
      error_key(:wsl_vagrant_version_mismatch)
    end

    class WSLVagrantAccessError < VagrantError
      error_key(:wsl_vagrant_access_error)
    end

    class WSLVirtualBoxWindowsAccessError < VagrantError
      error_key(:wsl_virtualbox_windows_access)
    end

    class WSLRootFsNotFoundError < VagrantError
      error_key(:wsl_rootfs_not_found_error)
    end
  end
end
