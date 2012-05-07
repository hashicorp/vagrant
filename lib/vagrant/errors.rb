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
      @@used_codes = []

      def self.status_code(code = nil)
        if code
          raise "Status code already in use: #{code}"  if @@used_codes.include?(code)
          @@used_codes << code
        end

        define_method(:status_code) { code }
      end

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

      protected

      def translate_error(opts)
        return nil if !opts[:_key]
        I18n.t("#{opts[:_namespace]}.#{opts[:_key]}", opts)
      end
    end

    class BaseVMNotFound < VagrantError
      status_code(18)
      error_key(:base_vm_not_found)
    end

    class BoxAlreadyExists < VagrantError
      status_code(14)
      error_key(:already_exists, "vagrant.actions.box.unpackage")
    end

    class BoxDownloadUnknownType < VagrantError
      status_code(13)
      error_key(:unknown_type, "vagrant.actions.box.download")
    end

    class BoxNotFound < VagrantError
      status_code(2)
      error_key(:box_not_found)
    end

    class BoxNotSpecified < VagrantError
      status_code(22)
      error_key(:not_specified, "vagrant.actions.vm.check_box")
    end

    class BoxSpecifiedDoesntExist < VagrantError
      status_code(23)
      error_key(:does_not_exist, "vagrant.actions.vm.check_box")
    end

    class BoxUnpackageFailure < VagrantError
      status_code(57)
      error_key(:untar_failure, "vagrant.actions.box.unpackage")
    end

    class BoxVerificationFailed < VagrantError
      status_code(15)
      error_key(:failed, "vagrant.actions.box.verify")
    end

    class CLIInvalidUsage < VagrantError
      status_code(69)
      error_key(:cli_invalid_usage)
    end

    class CLIInvalidOptions < VagrantError
      status_code(1)
      error_key(:cli_invalid_options)
    end

    class ConfigValidationFailed < VagrantError
      status_code(42)
      error_key(:config_validation)
    end

    class DeprecationError < VagrantError
      status_code(60)
      error_key(:deprecation)
    end

    class DestroyRequiresForce < VagrantError
      status_code(74)
      error_key(:destroy_requires_force)
    end

    class DotfileIsDirectory < VagrantError
      status_code(46)
      error_key(:dotfile_is_directory)
    end

    class DownloaderFileDoesntExist < VagrantError
      status_code(37)
      error_key(:file_missing, "vagrant.downloaders.file")
    end

    class DownloaderHTTPConnectTimeout < VagrantError
      status_code(79)
      error_key(:connection_timeout, "vagrant.downloaders.http")
    end

    class DownloaderHTTPSocketError < VagrantError
      status_code(38)
      error_key(:socket_error, "vagrant.downloaders.http")
    end

    class DownloaderHTTPStatusError < VagrantError
      status_code(51)
      error_key(:status_error, "vagrant.downloaders.http")
    end

    class EnvironmentNonExistentCWD < VagrantError
      status_code(75)
      error_key(:environment_non_existent_cwd)
    end

    class EnvironmentLockedError < VagrantError
      status_code(52)
      error_key(:environment_locked)
    end

    class GemCommandInBundler < VagrantError
      status_code(71)
      error_key(:gem_command_in_bundler)
    end

    class HomeDirectoryMigrationFailed < VagrantError
      status_code(53)
      error_key(:home_dir_migration_failed)
    end

    class HomeDirectoryNotAccessible < VagrantError
      status_code(55)
      error_key(:home_dir_not_accessible)
    end

    class ForwardPortAutolistEmpty < VagrantError
      status_code(27)
      error_key(:auto_empty, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortCollision < VagrantError
      status_code(26)
      error_key(:collision_error, "vagrant.actions.vm.forward_ports")
    end

    class ForwardPortCollisionResume < VagrantError
      status_code(62)
      error_key(:port_collision_resume)
    end

    class MultiVMEnvironmentRequired < VagrantError
      status_code(5)
      error_key(:multi_vm_required)
    end

    class MultiVMTargetRequired < VagrantError
      status_code(7)
      error_key(:multi_vm_target_required)
    end

    class NetworkAdapterCollision < VagrantError
      status_code(65)
      error_key(:adapter_collision, "vagrant.actions.vm.network")
    end

    class NetworkCollision < VagrantError
      status_code(29)
      error_key(:collides, "vagrant.actions.vm.host_only_network")
    end

    class NetworkNoAdapters < VagrantError
      status_code(64)
      error_key(:no_adapters, "vagrant.actions.vm.network")
    end

    class NetworkDHCPAlreadyAttached < VagrantError
      status_code(68)
      error_key(:dhcp_already_attached, "vagrant.actions.vm.network")
    end

    class NetworkNotFound < VagrantError
      status_code(30)
      error_key(:not_found, "vagrant.actions.vm.host_only_network")
    end

    class NFSHostRequired < VagrantError
      status_code(31)
      error_key(:host_required, "vagrant.actions.vm.nfs")
    end

    class NFSNotSupported < VagrantError
      status_code(32)
      error_key(:not_supported, "vagrant.actions.vm.nfs")
    end

    class NFSNoHostNetwork < VagrantError
      status_code(33)
      error_key(:no_host_network, "vagrant.actions.vm.nfs")
    end

    class NoEnvironmentError < VagrantError
      status_code(3)
      error_key(:no_env)
    end

    class PackageIncludeMissing < VagrantError
      status_code(20)
      error_key(:include_file_missing, "vagrant.actions.general.package")
    end

    class PackageOutputDirectory < VagrantError
      status_code(72)
      error_key(:output_is_directory, "vagrant.actions.general.package")
    end

    class PackageOutputExists < VagrantError
      status_code(16)
      error_key(:output_exists, "vagrant.actions.general.package")
    end

    class PackageRequiresDirectory < VagrantError
      status_code(19)
      error_key(:requires_directory, "vagrant.actions.general.package")
    end

    class PersistDotfileExists < VagrantError
      status_code(34)
      error_key(:dotfile_error, "vagrant.actions.vm.persist")
    end

    class PluginLoadError < VagrantError
      status_code(81)
      error_key(:plugin_load_error)
    end

    class SCPUnavailable < VagrantError
      status_code(56)
      error_key(:scp_unavailable)
    end

    class SharedFolderCreateFailed < VagrantError
      status_code(66)
      error_key(:shared_folder_create_failed)
    end

    class SSHAuthenticationFailed < VagrantError
      status_code(11)
      error_key(:ssh_authentication_failed)
    end

    class SSHConnectionRefused < VagrantError
      status_code(43)
      error_key(:ssh_connection_refused)
    end

    class SSHConnectionTimeout < VagrantError
      status_code(78)
      error_key(:ssh_connection_timeout)
    end

    class SSHKeyBadPermissions < VagrantError
      status_code(12)
      error_key(:ssh_key_bad_permissions)
    end

    class SSHKeyTypeNotSupported < VagrantError
      status_code(76)
      error_key(:ssh_key_type_not_supported)
    end

    class SSHPortNotDetected < VagrantError
      status_code(50)
      error_key(:ssh_port_not_detected)
    end

    class SSHUnavailable < VagrantError
      status_code(45)
      error_key(:ssh_unavailable)
    end

    class SSHUnavailableWindows < VagrantError
      status_code(10)
      error_key(:ssh_unavailable_windows)
    end

    class UIExpectsTTY < VagrantError
      status_code(73)
      error_key(:ui_expects_tty)
    end

    class VagrantInterrupt < VagrantError
      status_code(40)
      error_key(:interrupted)
    end

    class VagrantfileExistsError < VagrantError
      status_code(58)
      error_key(:vagrantfile_exists)
    end

    class VagrantfileSyntaxError < VagrantError
      status_code(41)
      error_key(:vagrantfile_syntax_error)
    end

    class VBoxManageError < VagrantError
      status_code(59)
      error_key(:vboxmanage_error)
    end

    class VirtualBoxInvalidVersion < VagrantError
      status_code(17)
      error_key(:virtualbox_invalid_version)
    end

    class VirtualBoxNotDetected < VagrantError
      status_code(8)
      error_key(:virtualbox_not_detected)
    end

    class VirtualBoxKernelModuleNotLoaded < VagrantError
      status_code(70)
      error_key(:virtualbox_kernel_module_not_loaded)
    end

    class VirtualBoxInstallIncomplete < VagrantError
      status_code(80)
      error_key(:virtualbox_install_incomplete)
    end

    class VMBaseMacNotSpecified < VagrantError
      status_code(47)
      error_key(:no_base_mac, "vagrant.actions.vm.match_mac")
    end

    class VMCustomizationFailed < VagrantError
      status_code(61)
      error_key(:failure, "vagrant.actions.vm.customize")
    end

    class VMFailedToBoot < VagrantError
      status_code(21)
      error_key(:failed_to_boot, "vagrant.actions.vm.boot")
    end

    class VMFailedToRun < VagrantError
      status_code(77)
      error_key(:failed_to_run, "vagrant.actions.vm.boot")
    end

    class VMGuestError < VagrantError
      status_code(39)
      error_namespace("vagrant.errors.guest")
    end

    class VMImportFailure < VagrantError
      status_code(28)
      error_key(:failure, "vagrant.actions.vm.import")
    end

    class VMInaccessible < VagrantError
      status_code(54)
      error_key(:vm_inaccessible)
    end

    class VMNoMatchError < VagrantError
      status_code(63)
      error_key(:vm_no_match)
    end

    class VMNotCreatedError < VagrantError
      status_code(6)
      error_key(:vm_creation_required)
    end

    class VMNotFoundError < VagrantError
      status_code(4)
      error_key(:vm_not_found)
    end

    class VMNotRunningError < VagrantError
      status_code(44)
      error_key(:vm_not_running)
    end

    class VMPowerOffToPackage < VagrantError
      status_code(24)
      error_key(:power_off, "vagrant.actions.vm.export")
    end
  end
end
