require "digest/md5"
require "tempfile"

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
        command = container_ssh_command
        return false if !command
        @host_vm.communicate.test("#{command} exit")
      end

      def download(from, to)
        # Same process as upload, but in reverse

        # First, we use `cat` to copy that file from the Docker container.
        temp = "/tmp/docker_d#{Time.now.to_i}_#{rand(100000)}"
        @host_vm.communicate.execute("#{container_ssh_command} 'cat #{from}' >#{temp}")

        # Then, we download this from the host VM.
        @host_vm.communicate.download(temp, to)

        # Remove the temporary file
        @host_vm.communicate.execute("rm -f #{temp}", error_check: false)
      end

      def execute(command, **opts, &block)
        fence = {}
        fence[:stderr] = "VAGRANT FENCE: #{Time.now.to_i} #{rand(100000)}"
        fence[:stdout] = "VAGRANT FENCE: #{Time.now.to_i} #{rand(100000)}"

        # We want to emulate how the SSH communicator actually executes
        # things, so we build up the list of commands to execute in a
        # giant shell script.
        tf = Tempfile.new("vagrant")
        tf.binmode
        tf.write("export TERM=vt100\n")
        tf.write("echo #{fence[:stdout]}\n")
        tf.write("echo #{fence[:stderr]} >&2\n")
        tf.write("#{command}\n")
        tf.write("exit\n")
        tf.close

        # Upload the temp file to the remote machine
        remote_temp = "/tmp/docker_#{Time.now.to_i}_#{rand(100000)}"
        @host_vm.communicate.upload(tf.path, remote_temp)

        # Determine the shell to execute. Prefer the explicitly passed in shell
        # over the default configured shell. If we are using `sudo` then we
        # need to wrap the shell in a `sudo` call.
        shell_cmd = @machine.config.ssh.shell
        shell_cmd = opts[:shell] if opts[:shell]
        shell_cmd = "sudo -E -H #{shell_cmd}" if opts[:sudo]

        acc    = {}
        fenced = {}
        result = @host_vm.communicate.execute(
          "#{container_ssh_command} '#{shell_cmd}' <#{remote_temp}",
          opts) do |type, data|
          # If we don't have a block, we don't care about the data
          next if !block

          # We only care about stdout and stderr output
          next if ![:stdout, :stderr].include?(type)

          # If we reached our fence, then just output
          if fenced[type]
            block.call(type, data)
            next
          end

          # Otherwise, accumulate
          acc[type] = data

          # Look for the fence
          index = acc[type].index(fence[type])
          next if !index

          fenced[type] = true
          index += fence[type].length
          data  = acc[type][index..-1].chomp
          acc[type] = ""
          block.call(type, data)
        end

        @host_vm.communicate.execute("rm -f #{remote_temp}", error_check: false)

        return result
      end

      def sudo(command, **opts, &block)
        opts = { sudo: true }.merge(opts)
        execute(command, opts, &block)
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
        @host_vm.communicate.execute("rm -f #{to_temp}", error_check: false)
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
        return nil if !info
        info[:port] ||= 22

        # Make sure our private keys are synced over to the host VM
        ssh_args = sync_private_keys(info).map do |path|
          "-i #{path}"
        end

        # Use ad-hoc SSH options for the hop on the docker proxy 
        if info[:forward_agent]
          ssh_args << "-o ForwardAgent=yes"
        end
        ssh_args.concat(["-o Compression=yes",
                         "-o ConnectTimeout=5",
                         "-o StrictHostKeyChecking=no",
                         "-o UserKnownHostsFile=/dev/null"])

        # Build the SSH command
        "ssh #{info[:username]}@#{info[:host]} -p#{info[:port]} #{ssh_args.join(" ")}"
      end

      protected

      def sync_private_keys(info)
        @keys ||= {}

        id = Digest::MD5.hexdigest(
          @machine.env.root_path.to_s + @machine.name.to_s)

        result = []
        info[:private_key_path].each do |path|
          if !@keys[path.to_s]
            # We haven't seen this before, upload it!
            guest_path = "/tmp/key_#{id}_#{Digest::MD5.hexdigest(path.to_s)}"
            @host_vm.communicate.upload(path.to_s, guest_path)

            # Make sure it has the proper chmod
            @host_vm.communicate.execute("chmod 0600 #{guest_path}")

            # Set it
            @keys[path.to_s] = guest_path
          end

          result << @keys[path.to_s]
        end

        result
      end
    end
  end
end
