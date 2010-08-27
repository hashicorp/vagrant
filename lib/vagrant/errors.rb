module Vagrant
  # Main superclass of any errors in Vagrant. This provides some
  # convenience methods for setting the status code and error key.
  # The status code is used by the `vagrant` executable as the
  # error code, and the error key is used as a default message from
  # I18n.
  class VagrantError < StandardError
    def self.status_code(code = nil)
      define_method(:status_code) { code }
    end

    def self.error_key(key=nil)
      define_method(:error_key) { key }
    end

    def initialize(message=nil, *args)
      message = I18n.t("vagrant.errors.#{error_key}", message) if respond_to?(:error_key)
      super
    end
  end

  class BaseVMNotFound < VagrantError
    status_code(6)
    error_key(:base_vm_not_found)
  end

  class BoxNotFound < VagrantError
    status_code(2)
    error_key(:box_not_found)
  end

  class CLIMissingEnvironment < VagrantError
    status_code(1)
    error_key(:cli_missing_environment)
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
    error_key(:no_environment)
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
