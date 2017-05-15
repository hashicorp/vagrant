module VagrantPlugins
  module DockerProvider
    module Errors
      class DockerError < Vagrant::Errors::VagrantError
        error_namespace("docker_provider.errors")
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
