require "fileutils"

require "log4r"

require "vagrant/action/builtin/mixin_synced_folders"
require "vagrant/util/silence_warnings"

module VagrantPlugins
  module DockerProvider
    class Provider < Vagrant.plugin("2", :provider)
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
            if !vf_path.file?
              @machine.env.lock("docker-provider-hostvm") do
                vf_path.dirname.mkpath
                FileUtils.cp(default_path, vf_path)
              end
            end
          rescue Vagrant::Errors::EnvironmentLockedError
            # Lock contention, just retry
            retry
          end

          # Set the machine name since we hardcode that for the default
          host_machine_name = :default
        end

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

          # TODO(mitchellh): configure the provider of this machine somehow
          host_env.machine(host_machine_name, :virtualbox)
        end

        # Make sure we swap all the synced folders out from our
        # machine so that we do a double synced folder: normal synced
        # folders to the host machine, then Docker volumes within that host.
        sf_helper_klass = Class.new do
          include Vagrant::Action::Builtin::MixinSyncedFolders
        end
        sf_helper   = sf_helper_klass.new
        our_folders = sf_helper.synced_folders(@machine)
        if our_folders[:docker]
          our_folders[:docker].each do |id, data|
            data = data.dup
            data.delete(:type)

            # Add them to the host machine
=begin
            @host_vm.config.vm.synced_folder(
              data[:hostpath],
              data[:guestpath],
              data)
=end

            # Remove from our machine
            @machine.config.vm.synced_folders.delete(id)
          end
        end

        @host_vm
      end

      # This says whether or not Docker will be running within a VM
      # rather than directly on our system. Docker needs to run in a VM
      # when we're not on Linux, or not on a Linux that supports Docker.
      def host_vm?
        # TODO: It'd be nice to also check if Docker supports the version
        # of Linux that Vagrant is running on so that we can spin up a VM
        # on old versions of Linux as well.
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

        { host: ip }
      end

      def state
        state_id = nil
        state_id = :host_state_unknown if host_vm? && !host_vm.communicate.ready?
        state_id = :not_created if !state_id && \
          (!@machine.id || !driver.created?(@machine.id))
        state_id = driver.state(@machine.id) if @machine.id && !state_id
        state_id = :unknown if !state_id

        short = state_id.to_s.gsub("_", " ")
        long  = I18n.t("docker_provider.status.#{state_id}")

        Vagrant::MachineState.new(state_id, short, long)
      end

      def to_s
        id = @machine.id ? @machine.id : "new container"
        "Docker (#{id})"
      end
    end
  end
end
