module VagrantPlugins
  module DockerProvider
    # This communicator uses the host VM as proxy to communicate to the
    # actual Docker container via SSH.
    class Communicator < Vagrant.plugin("2", :communicator)
      def initialize(machine)
        @machine = machine
        @host_vm = machine.provider.host_vm

        # We only work on the Docker provider
        if machine.provider_name != :docker
          raise Errors::CommunicatorNotDocker
        end
      end

      #-------------------------------------------------------------------
      # Communicator Methods
      #-------------------------------------------------------------------

      def ready?
        # We can't be ready if we can't talk to the host VM
        return false if !@host_vm.communicate.ready?

        # We're ready if we can establish an SSH connection to the container
        @host_vm.communicate.test("#{container_ssh_command} exit")
      end

      def download(from, to)
        raise "NOT IMPLEMENTED YET"
      end

      def execute(command, opts=nil, &block)
        @host_vm.communicate.execute(
          "#{container_ssh_command} #{command}", opts, &block)
      end

      def sudo(command, opts=nil)
      end

      def test(command, **opts)
        opts = { error_check: false }.merge(opts)
        execute(command, opts) == 0
      end

      def upload(from, to)
        # First, we upload this to the host VM to some temporary directory.
        to_temp = "/tmp/docker_#{Time.now.to_i}_#{rand(100000)}"
        @host_vm.communicate.upload(from, to_temp)

        # Then, we use `cat` to get that file into the Docker container.
        @host_vm.communicate.execute(
          "#{container_ssh_command} 'cat >#{to}' <#{to_temp}")

        # Remove the temporary file
        @host_vm.communicate.execute("rm #{to_temp}", error_check: false)
      end

      #-------------------------------------------------------------------
      # Other Methods
      #-------------------------------------------------------------------

      # This returns the raw SSH command string that can be used to
      # connect via SSH to the container if you're on the same machine
      # as the container.
      #
      # @return [String]
      def container_ssh_command
        # Get the container's SSH info
        info = @machine.ssh_info
        info[:port] ||= 22

        # Build the SSH command
        "ssh -i /home/vagrant/insecure " +
          "-o Compression=yes " +
          "-o ConnectTimeout=5 " +
          "-o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null " +
          "-p#{info[:port]} " +
          "#{info[:username]}@#{info[:host]}"
      end
    end
  end
end
