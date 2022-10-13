module VagrantPlugins
  module DockerProvider
    module Errors
      class DockerError < Vagrant::Errors::VagrantError
        error_namespace("docker_provider.errors")
      end

      class BuildError < DockerError
        error_key(:build_error)
      end

      class CommunicatorNonDocker < DockerError
        error_key(:communicator_non_docker)
      end

      class ComposeLockTimeoutError < DockerError
        error_key(:compose_lock_timeout)
      end

      class ContainerNotRunningError < DockerError
        error_key(:not_running)
      end

      class ContainerNotCreatedError < DockerError
        error_key(:not_created)
      end

      class DockerComposeNotInstalledError < DockerError
        error_key(:docker_compose_not_installed)
      end

      class ExecuteError < DockerError
        error_key(:execute_error)
      end

      class ExecCommandRequired < DockerError
        error_key(:exec_command_required)
      end

      class HostVMCommunicatorNotReady < DockerError
        error_key(:host_vm_communicator_not_ready)
      end

      class ImageNotConfiguredError < DockerError
        error_key(:docker_provider_image_not_configured)
      end

      class NfsWithoutPrivilegedError < DockerError
        error_key(:docker_provider_nfs_without_privileged)
      end

      class NetworkAddressInvalid < DockerError
        error_key(:network_address_invalid)
      end

      class NetworkIPAddressRequired < DockerError
        error_key(:network_address_required)
      end

      class NetworkSubnetInvalid < DockerError
        error_key(:network_subnet_invalid)
      end

      class NetworkInvalidOption < DockerError
        error_key(:network_invalid_option)
      end

      class NetworkNameMissing < DockerError
        error_key(:network_name_missing)
      end

      class NetworkNameUndefined < DockerError
        error_key(:network_name_undefined)
      end

      class NetworkNoInterfaces < DockerError
        error_key(:network_no_interfaces)
      end

      class PackageNotSupported < DockerError
        error_key(:package_not_supported)
      end

      class StateNotRunning < DockerError
        error_key(:state_not_running)
      end

      class StateStopped < DockerError
        error_key(:state_stopped)
      end

      class SuspendNotSupported < DockerError
        error_key(:suspend_not_supported)
      end

      class SyncedFolderNonDocker < DockerError
        error_key(:synced_folder_non_docker)
      end

      class VagrantfileNotFound < DockerError
        error_key(:vagrantfile_not_found)
      end
    end
  end
end
