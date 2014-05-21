module VagrantPlugins
  module DockerProvider
    module Errors
      class DockerError < Vagrant::Errors::VagrantError
        error_namespace("docker_provider.errors")
      end

      class CommunicatorNonDocker < DockerError
        error_key(:communicator_non_docker)
      end

      class ExecuteError < DockerError
        error_key(:execute_error)
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

      class StateNotRunning < DockerError
        error_key(:state_not_running)
      end

      class StateStopped < DockerError
        error_key(:state_stopped)
      end

      class SyncedFolderNonDocker < DockerError
        error_key(:synced_folder_non_docker)
      end
    end
  end
end
