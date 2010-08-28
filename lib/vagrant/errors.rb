# This file contains all of the internal errors in Vagrant's core
# commands, actions, etc.

module Vagrant
  module Errors
    # Main superclass of any errors in Vagrant. This provides some
    # convenience methods for setting the status code and error key.
    # The status code is used by the `vagrant` executable as the
    # error code, and the error key is used as a default message from
    # I18n.
    class VagrantError < StandardError
      DEFAULT_NAMESPACE = "vagrant.errors"

      def self.status_code(code = nil)
        define_method(:status_code) { code }
      end

      def self.error_key(key=nil, namespace=nil)
        define_method(:error_key) { key }
        define_method(:error_namespace) { namespace } if namespace
      end

      def initialize(message=nil, *args)
        message = translate_error(error_key, message) if respond_to?(:error_key)
        super
      end

      protected

      def translate_error(key, opts=nil)
        namespace = respond_to?(:error_namespace) ? error_namespace : DEFAULT_NAMESPACE
        I18n.t("#{namespace}.#{key}", opts)
      end
    end

    class BaseVMNotFound < VagrantError
      status_code(6)
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

    class BoxVerificationFailed < VagrantError
      status_code(15)
      error_key(:failed, "vagrant.actions.box.verify")
    end

    class CLIMissingEnvironment < VagrantError
      status_code(1)
      error_key(:cli_missing_env)
    end

    class MultiVMEnvironmentRequired < VagrantError
      status_code(5)
      error_key(:multi_vm_required)
    end

    class MultiVMTargetRequired < VagrantError
      status_code(7)
      error_key(:multi_vm_target_required)
    end

    class NoEnvironmentError < VagrantError
      status_code(3)
      error_key(:no_env)
    end

    class SSHAuthenticationFailed < VagrantError
      status_code(11)
      error_key(:ssh_authentication_failed)
    end

    class SSHKeyBadPermissions < VagrantError
      status_code(12)
      error_key(:ssh_key_bad_permissions)
    end

    class SSHUnavailableWindows < VagrantError
      status_code(10)
      error_key(:ssh_unavailable_windows)
    end

    class VirtualBoxInvalidOSE < VagrantError
      status_code(9)
      error_key(:virtualbox_invalid_ose)
    end

    class VirtualBoxInvalidVersion < VagrantError
      status_code(9)
      error_key(:virtualbox_invalid_version)
    end

    class VirtualBoxNotDetected < VagrantError
      status_code(8)
      error_key(:virtualbox_not_detected)
    end

    class VMNotCreatedError < VagrantError
      status_code(6)
      error_key(:vm_creation_required)
    end

    class VMNotFoundError < VagrantError
      status_code(4)
      error_key(:vm_not_found)
    end
  end
end
