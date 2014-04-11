module VagrantPlugins
  module DockerProvider
    module Action
      class Create
        def initialize(app, env)
          @app = app
          @@mutex ||= Mutex.new
        end

        def call(env)
          @env             = env
          @machine         = env[:machine]
          @provider_config = @machine.provider_config
          @machine_config  = @machine.config
          @driver          = @machine.provider.driver

          guard_cmd_configured!

          params = create_params

          cid = ''
          @@mutex.synchronize do
            env[:ui].output(I18n.t("docker_provider.creating"))
            env[:ui].detail(" Name: #{params[:name]}")
            env[:ui].detail("Image: #{params[:image]}")

            cid = @driver.create(params)
          end

          env[:ui].detail(" \n"+I18n.t(
            "docker_provider.created", id: cid[0...16]))
          @machine.id = cid
          @app.call(env)
        end

        def create_params
          container_name = "#{@env[:root_path].basename.to_s}_#{@machine.name}"
          container_name.gsub!(/[^-a-z0-9_]/i, "")
          container_name << "_#{Time.now.to_i}"

          {
            cmd:        @provider_config.cmd,
            extra_args: @provider_config.create_args,
            hostname:   @machine_config.vm.hostname,
            image:      @provider_config.image,
            name:       container_name,
            ports:      forwarded_ports,
            privileged: @provider_config.privileged,
            volumes:    @provider_config.volumes,
          }
        end

        def forwarded_ports
          @env[:forwarded_ports].map do |fp|
            # TODO: Support for the protocol argument
            "#{fp[:host]}:#{fp[:guest]}"
          end.compact
        end

        def guard_cmd_configured!
          if ! @provider_config.image
            raise Errors::ImageNotConfiguredError, name: @machine.name
          end
        end
      end
    end
  end
end
