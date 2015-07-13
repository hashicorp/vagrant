require "digest/md5"
require "fileutils"
require "thread"

require "log4r"

require "vagrant/util/silence_warnings"

module VagrantPlugins
  module DockerProvider
    class Provider < Vagrant.plugin("2", :provider)
      @@host_vm_mutex = Mutex.new

      def initialize(machine)
        @logger  = Log4r::Logger.new("vagrant::provider::docker")
        @machine = machine

        if host_vm?
          # We need to use a special communicator that proxies our
          # SSH requests over our host VM to the container itself.
          @machine.config.vm.communicator = :docker_hostvm
        end
      end

      # @see Vagrant::Plugin::V2::Provider#action
      def action(name)
        action_method = "action_#{name}"
        return Action.send(action_method) if Action.respond_to?(action_method)
        nil
      end

      # Returns the driver instance for this provider.
      def driver
        return @driver if @driver
        @driver = Driver.new

        # If we are running on a host machine, then we set the executor
        # to execute remotely.
        if host_vm?
          @driver.executor = Executor::Vagrant.new(host_vm)
        end

        @driver
      end

      # This returns the {Vagrant::Machine} that is our host machine.
      # It does not perform any action on the machine or verify it is
      # running.
      #
      # @return [Vagrant::Machine]
      def host_vm
        return @host_vm if @host_vm

        vf_path           = @machine.provider_config.vagrant_vagrantfile
        host_machine_name = @machine.provider_config.vagrant_machine || :default
        if !vf_path
          # We don't have a Vagrantfile path set, so we're going to use
          # the default but we need to copy it into the data dir so that
          # we don't write into our installation dir (we can't).
          default_path = File.expand_path("../hostmachine/Vagrantfile", __FILE__)
          vf_path      = @machine.env.data_dir.join("docker-host", "Vagrantfile")
          begin
            @machine.env.lock("docker-provider-hostvm") do
              vf_path.dirname.mkpath
              FileUtils.cp(default_path, vf_path)
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            # Lock contention, just retry
            retry
          end

          # Set the machine name since we hardcode that for the default
          host_machine_name = :default
        end

        # Expand it so that the home directories and so on get processed
        # properly.
        vf_path = File.expand_path(vf_path, @machine.env.root_path)

        vf_file = File.basename(vf_path)
        vf_path = File.dirname(vf_path)

        # Create the env to manage this machine
        @host_vm = Vagrant::Util::SilenceWarnings.silence! do
          host_env = Vagrant::Environment.new(
            cwd: vf_path,
            home_path: @machine.env.home_path,
            ui_class: @machine.env.ui_class,
            vagrantfile_name: vf_file,
          )

          # If there is no root path, then the Vagrantfile wasn't found
          # and it is an error...
          raise Errors::VagrantfileNotFound if !host_env.root_path

          host_env.machine(
            host_machine_name,
            host_env.default_provider(
              exclude: [:docker],
              force_default: false,
            ))
        end

        @host_vm
      end

      # This acquires a lock on the host VM.
      def host_vm_lock
        hash = Digest::MD5.hexdigest(host_vm.data_dir.to_s)

        # We do a process-level mutex on the outside, since we can
        # wait for that a short amount of time. Then, we do a process lock
        # on the inside, which will raise an exception if locked.
        host_vm_mutex.synchronize do
          @machine.env.lock(hash) do
            return yield
          end
        end
      end

      # This is a process-local mutex that can be used by parallel
      # providers to lock the host VM access.
      def host_vm_mutex
        @@host_vm_mutex
      end

      # This says whether or not Docker will be running within a VM
      # rather than directly on our system. Docker needs to run in a VM
      # when we're not on Linux, or not on a Linux that supports Docker.
      def host_vm?
        @machine.provider_config.force_host_vm ||
          !Vagrant::Util::Platform.linux?
      end

      # Returns the SSH info for accessing the Container.
      def ssh_info
        # If the container isn't running, we can't SSH into it
        return nil if state.id != :running

        network = driver.inspect_container(@machine.id)['NetworkSettings']
        ip      = network['IPAddress']

        # If we were not able to identify the container's IP, we return nil
        # here and we let Vagrant core deal with it ;)
        return nil if !ip

        {
          host: ip,
          port: @machine.config.ssh.guest_port
        }
      end

      def state
        state_id = nil
        state_id = :not_created if !@machine.id

        begin
          state_id = :host_state_unknown if !state_id && \
            host_vm? && !host_vm.communicate.ready?
        rescue Errors::VagrantfileNotFound
          state_id = :host_state_unknown
        end

        state_id = :not_created if !state_id && \
          (!@machine.id || !driver.created?(@machine.id))
        state_id = driver.state(@machine.id) if @machine.id && !state_id
        state_id = :unknown if !state_id

        # This is a special pseudo-state so that we don't set the
        # NOT_CREATED_ID while we're setting up the machine. This avoids
        # clearing the data dir.
        state_id = :preparing if @machine.id == "preparing"

        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("docker_provider.status.#{state_id}")

        # If we're not created, then specify the special ID flag
        if state_id == :not_created
          state_id = Vagrant::MachineState::NOT_CREATED_ID
        end

        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id ? @machine.id : "new container"
        "Docker (#{id})"
      end
    end
  end
end
