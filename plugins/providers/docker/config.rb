require "pathname"

module VagrantPlugins
  module DockerProvider
    class Config < Vagrant.plugin("2", :config)
      attr_accessor :image, :cmd, :ports, :volumes, :privileged

      # Additional arguments to pass to `docker build` when creating
      # an image using the build dir setting.
      #
      # @return [Array<String>]
      attr_accessor :build_args

      # The directory with a Dockerfile to build and use as the basis
      # for this container. If this is set, "image" should not be set.
      #
      # @return [String]
      attr_accessor :build_dir

      # An optional file name of a Dockerfile to be used when building
      # the image. This requires Docker >1.5.0.
      #
      # @return [String]
      attr_accessor :dockerfile

      # Additional arguments to pass to `docker run` when creating
      # the container for the first time. This is an array of args.
      #
      # @return [Array<String>]
      attr_accessor :create_args

      # Environmental variables to set in the container.
      #
      # @return [Hash]
      attr_accessor :env

      # Ports to expose from the container but not to the host machine.
      # This is useful for links.
      #
      # @return [Array<Integer>]
      attr_accessor :expose

      # Force using a proxy VM, even on Linux hosts.
      #
      # @return [Boolean]
      attr_accessor :force_host_vm

      # True if the Docker container exposes SSH access. If this is true,
      # then Vagrant can do a bunch more things like setting the hostname,
      # provisioning, etc.
      attr_accessor :has_ssh

      # Options for the build dir synced folder if a host VM is in use.
      #
      # @return [Hash]
      attr_accessor :host_vm_build_dir_options

      # The name for the container. This must be unique for all containers
      # on the proxy machine if it is made.
      #
      # @return [String]
      attr_accessor :name

      # If true, the image will be pulled on every `up` and `reload`
      # to ensure the latest image.
      #
      # @return [Bool]
      attr_accessor :pull

      # True if the docker container is meant to stay in the "running"
      # state (is a long running process). By default this is true.
      #
      # @return [Boolean]
      attr_accessor :remains_running

      # The time to wait before sending a SIGTERM to the container
      # when it is stopped.
      #
      # @return [Integer]
      attr_accessor :stop_timeout

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

      #--------------------------------------------------------------
      # Auth Settings
      #--------------------------------------------------------------

      # Server to authenticate to. If blank, will use the default
      # Docker authentication endpoint (which is the Docker Hub at the
      # time of this comment).
      #
      # @return [String]
      attr_accessor :auth_server

      # Email for logging in to a remote Docker server.
      #
      # @return [String]
      attr_accessor :email

      # Email for logging in to a remote Docker server.
      #
      # @return [String]
      attr_accessor :username

      # Password for logging in to a remote Docker server. If this is
      # not blank, then Vagrant will run `docker login` prior to any
      # Docker runs.
      #
      # The presence of auth will also force the Docker environments to
      # serialize on `up` so that different users/passwords don't overlap.
      #
      # @return [String]
      attr_accessor :password

      def initialize
        @build_args = []
        @build_dir  = UNSET_VALUE
        @cmd        = UNSET_VALUE
        @create_args = UNSET_VALUE
        @dockerfile = UNSET_VALUE
        @env        = {}
        @expose     = []
        @force_host_vm = UNSET_VALUE
        @has_ssh    = UNSET_VALUE
        @host_vm_build_dir_options = UNSET_VALUE
        @image      = UNSET_VALUE
        @name       = UNSET_VALUE
        @links      = []
        @pull       = UNSET_VALUE
        @ports      = UNSET_VALUE
        @privileged = UNSET_VALUE
        @remains_running = UNSET_VALUE
        @stop_timeout = UNSET_VALUE
        @volumes    = []
        @vagrant_machine = UNSET_VALUE
        @vagrant_vagrantfile = UNSET_VALUE

        @auth_server = UNSET_VALUE
        @email    = UNSET_VALUE
        @username = UNSET_VALUE
        @password = UNSET_VALUE
      end

      def link(name)
        @links << name
      end

      def merge(other)
        super.tap do |result|
          # This is a bit confusing. The tests explain the purpose of this
          # better than the code lets on, I believe.
          if (other.image != UNSET_VALUE || other.build_dir != UNSET_VALUE) &&
            (other.image == UNSET_VALUE || other.build_dir == UNSET_VALUE)
            if other.image != UNSET_VALUE && @build_dir != UNSET_VALUE
              result.build_dir = nil
            end

            if other.build_dir != UNSET_VALUE && @image != UNSET_VALUE
              result.image = nil
            end
          end

          env = {}
          env.merge!(@env) if @env
          env.merge!(other.env) if other.env
          result.env = env

          expose = self.expose.dup
          expose += other.expose
          result.instance_variable_set(:@expose, expose)

          links = _links.dup
          links += other._links
          result.instance_variable_set(:@links, links)
        end
      end

      def finalize!
        @build_args = [] if @build_args == UNSET_VALUE
        @build_dir  = nil if @build_dir == UNSET_VALUE
        @cmd        = [] if @cmd == UNSET_VALUE
        @create_args = [] if @create_args == UNSET_VALUE
        @dockerfile = nil if @dockerfile == UNSET_VALUE
        @env       ||= {}
        @force_host_vm = false if @force_host_vm == UNSET_VALUE
        @has_ssh    = false if @has_ssh == UNSET_VALUE
        @image      = nil if @image == UNSET_VALUE
        @name       = nil if @name == UNSET_VALUE
        @pull       = false if @pull == UNSET_VALUE
        @ports      = [] if @ports == UNSET_VALUE
        @privileged = false if @privileged == UNSET_VALUE
        @remains_running = true if @remains_running == UNSET_VALUE
        @stop_timeout = 1 if @stop_timeout == UNSET_VALUE
        @vagrant_machine = nil if @vagrant_machine == UNSET_VALUE
        @vagrant_vagrantfile = nil if @vagrant_vagrantfile == UNSET_VALUE

        @auth_server = nil if @auth_server == UNSET_VALUE
        @email = "" if @email == UNSET_VALUE
        @username = "" if @username == UNSET_VALUE
        @password = "" if @password == UNSET_VALUE

        if @host_vm_build_dir_options == UNSET_VALUE
          @host_vm_build_dir_options = nil
        end

        # The machine name must be a symbol
        @vagrant_machine = @vagrant_machine.to_sym if @vagrant_machine

        @expose.uniq!
      end

      def validate(machine)
        errors = _detected_errors

        if @build_dir && @image
          errors << I18n.t("docker_provider.errors.config.both_build_and_image")
        end

        if !@build_dir && !@image
          errors << I18n.t("docker_provider.errors.config.build_dir_or_image")
        end

        if @build_dir
          build_dir_pn = Pathname.new(@build_dir)
          if !build_dir_pn.directory?
            errors << I18n.t("docker_provider.errors.config.build_dir_invalid")
          end
        end

        if !@create_args.is_a?(Array)
          errors << I18n.t("docker_provider.errors.config.create_args_array")
        end

        @links.each do |link|
          parts = link.split(":")
          if parts.length != 2 || parts[0] == "" || parts[1] == ""
            errors << I18n.t(
              "docker_provider.errors.config.invalid_link", link: link)
          end
        end

        if @vagrant_vagrantfile
          vf_pn = Pathname.new(@vagrant_vagrantfile)
          if !vf_pn.file?
            errors << I18n.t("docker_provider.errors.config.invalid_vagrantfile")
          end
        end

        { "docker provider" => errors }
      end

      #--------------------------------------------------------------
      # Functions below should not be called by config files
      #--------------------------------------------------------------

      def _links
        @links
      end
    end
  end
end
