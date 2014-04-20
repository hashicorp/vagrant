module VagrantPlugins
  module DockerProvider
    module Action
      class Create
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env             = env
          @machine         = env[:machine]
          @provider_config = @machine.provider_config
          @machine_config  = @machine.config
          @driver          = @machine.provider.driver

          params = create_params

          env[:ui].output(I18n.t("docker_provider.creating"))
          env[:ui].detail("  Name: #{params[:name]}")
          env[:ui].detail(" Image: #{params[:image]}")
          params[:volumes].each do |volume|
            env[:ui].detail("Volume: #{volume}")
          end
          params[:ports].each do |pair|
            env[:ui].detail("  Port: #{pair}")
          end
          params[:links].each do |name, other|
            env[:ui].detail("  Link: #{name}:#{other}")
          end

          cid = @driver.create(params)

          env[:ui].detail(" \n"+I18n.t(
            "docker_provider.created", id: cid[0...16]))
          @machine.id = cid
          @app.call(env)
        end

        def create_params
          container_name = @provider_config.name
          if !container_name
            container_name = "#{@env[:root_path].basename.to_s}_#{@machine.name}"
            container_name.gsub!(/[^-a-z0-9_]/i, "")
            container_name << "_#{Time.now.to_i}"
          end

          image = @env[:create_image]
          image ||= @provider_config.image

          links = {}
          @provider_config._links.each do |link|
            parts = link.split(":", 2)
            links[parts[0]] = parts[1]
          end

          {
            cmd:        @provider_config.cmd,
            env:        @provider_config.env,
            extra_args: @provider_config.create_args,
            hostname:   @machine_config.vm.hostname,
            image:      image,
            links:      links,
            name:       container_name,
            ports:      forwarded_ports,
            privileged: @provider_config.privileged,
            volumes:    @provider_config.volumes,
          }
        end

        def forwarded_ports
          mappings = {}
          @machine.config.vm.networks.each do |type, options|
            if type == :forwarded_port
              mappings[options[:host]] = options
            end
          end

          mappings.values.map do |fp|
            # TODO: Support for the protocol argument
            "#{fp[:host]}:#{fp[:guest]}"
          end.compact
        end
      end
    end
  end
end
