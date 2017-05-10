require "json"
require "log4r"

module VagrantPlugins
  module DockerProvider
    class Driver
      class Compose < Driver

        # @return [String] Compose file format version
        COMPOSE_VERSION = "2".freeze

        # @return [Pathname] data directory to store composition
        attr_reader :data_directory
        # @return [Vagrant::Machine]
        attr_reader :machine

        # Create a new driver instance
        #
        # @param [Vagrant::Machine] machine Machine instance for this driver
        def initialize(machine)
          super()
          @machine = machine
          @data_directory = Pathname.new(machine.env.local_data_path).
            join("docker-compose")
          @data_directory.mkpath
          @logger = Log4r::Logger.new("vagrant::docker::driver::compose")
          @compose_lock = Mutex.new
        end

        def build(dir, **opts, &block)
          update_composition do |composition|
            composition["build"] = dir
          end
        end

        def create(params, **opts, &block)
          # NOTE: Use the direct machine name as we don't
          # need to worry about uniqueness with compose
          name    = machine.name.to_s
          image   = params.fetch(:image)
          links   = params.fetch(:links)
          ports   = Array(params[:ports])
          volumes = Array(params[:volumes])
          cmd     = Array(params.fetch(:cmd))
          env     = params.fetch(:env)
          expose  = Array(params[:expose])

          begin
            update_composition do |composition|
              services = composition["services"] ||= {}
              services[name] = {
                "image" => image,
                "environment" => env,
                "expose" => expose,
                "ports" => ports,
                "volumes" => volumes,
                "links" => links,
                "command" => cmd
              }
            end
          rescue
            update_composition(false) do |composition|
              composition["services"].delete(name)
            end
            raise
          end
          get_container_id(name)
        end

        def rm(cid)
          if created?(cid)
            destroy = false
            compose_execute("rm", "-f", machine.name.to_s)
            update_composition do |composition|
              if composition["services"] && composition["services"].key?(machine.name.to_s)
                @logger.info("Removing container `#{machine.name}`")
                composition["services"].delete(machine.name.to_s)
                destroy = composition["services"].empty?
              end
            end
            if destroy
              @logger.info("No containers remain. Destroying full environment.")
              compose_execute("down", "--remove-orphans")
            end
          end
        end

        def created?(cid)
          result = super
          if !result
            composition = get_current_composition
            if composition["services"] && composition["services"].has_key?(machine.name.to_s)
              result = true
            end
          end
          result
        end

        private

        # Lookup the ID for the container with the given name
        #
        # @param [String] name Name of container
        # @return [String] Container ID
        def get_container_id(name)
          compose_execute("ps", "-q", name).chomp
        end

        # Execute a `docker-compose` command
        def compose_execute(*cmd, **opts)
          @compose_lock.synchronize do
            execute("docker-compose", "-f", composition_path.to_s,
              "-p", machine.env.cwd.basename.to_s, *cmd, **opts)
          end
        end

        # Apply any changes made to the composition
        def apply_composition!
          machine.env.lock("compose", retry: true) do
            compose_execute("up", "-d", "--remove-orphans")
          end
        end

        # Update the composition and apply changes if requested
        #
        # @param [Boolean] apply Apply composition changes
        def update_composition(apply=true)
          machine.env.lock("compose", retry: true) do
            composition = get_current_composition
            yield composition
            write_composition(composition)
            apply_composition! if apply
          end
        end

        # @return [Hash] current composition contents
        def get_current_composition
          composition = {"version" => COMPOSE_VERSION.dup}
          if composition_path.exist?
            composition.merge!(
              YAML.load(composition_path.read)
            )
          end
          composition
        end

        # Save the composition
        #
        # @param [Hash] composition New composition
        def write_composition(composition)
          tmp_file = Tempfile.new("vagrant-docker-compose")
          tmp_file.write(composition.to_yaml)
          tmp_file.close
          @compose_lock.synchronize do
            FileUtils.mv(tmp_file.path, composition_path.to_s)
          end
        end

        # @return [Pathname] path to the docker-compose.yml file
        def composition_path
          data_directory.join("docker-compose.yml")
        end
      end
    end
  end
end
