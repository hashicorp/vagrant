module VagrantPlugins
  module DockerProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :image, :cmd, :ports, :volumes, :privileged

      # Additional arguments to pass to `docker run` when creating
      # the container for the first time. This is an array of args.
      #
      # @return [Array<String>]
      attr_accessor :create_args

      # Environmental variables to set in the container.
      #
      # @return [Hash]
      attr_accessor :env

      # True if the Docker container exposes SSH access. If this is true,
      # then Vagrant can do a bunch more things like setting the hostname,
      # provisioning, etc.
      attr_accessor :has_ssh

      # True if the docker container is meant to stay in the "running"
      # state (is a long running process). By default this is true.
      #
      # @return [Boolean]
      attr_accessor :remains_running

      # The name of the machine in the Vagrantfile set with
      # "vagrant_vagrantfile" that will be the docker host. Defaults
      # to "default"
      #
      # See the "vagrant_vagrantfile" docs for more info.
      #
      # @return [String]
      attr_accessor :vagrant_machine

      # The path to the Vagrantfile that contains a VM that will be
      # started as the Docker host if needed (Windows, OS X, Linux
      # without container support).
      #
      # Defaults to a built-in Vagrantfile that will load boot2docker.
      #
      # NOTE: This only has an effect if Vagrant needs a Docker host.
      # Vagrant determines this automatically based on the environment
      # it is running in.
      #
      # @return [String]
      attr_accessor :vagrant_vagrantfile

      def initialize
        @cmd        = UNSET_VALUE
        @create_args = []
        @env        = {}
        @has_ssh    = UNSET_VALUE
        @image      = UNSET_VALUE
        @ports      = []
        @privileged = UNSET_VALUE
        @remains_running = UNSET_VALUE
        @volumes    = []
        @vagrant_machine = UNSET_VALUE
        @vagrant_vagrantfile = UNSET_VALUE
      end

      def merge(other)
        super.tap do |result|
          env = {}
          env.merge!(@env) if @env
          env.merge!(other.env) if other.env
          result.env = env
        end
      end

      def finalize!
        @cmd        = [] if @cmd == UNSET_VALUE
        @create_args = [] if @create_args == UNSET_VALUE
        @env       ||= {}
        @has_ssh    = false if @has_ssh == UNSET_VALUE
        @image      = nil if @image == UNSET_VALUE
        @privileged = false if @privileged == UNSET_VALUE
        @remains_running = true if @remains_running == UNSET_VALUE
        @vagrant_machine = nil if @vagrant_machine == UNSET_VALUE
        @vagrant_vagrantfile = nil if @vagrant_vagrantfile == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # TODO: Detect if base image has a CMD / ENTRYPOINT set before erroring out
        errors << I18n.t("docker_provider.errors.config.cmd_not_set") if @cmd == UNSET_VALUE

        { "docker provider" => errors }
      end
    end
  end
end
