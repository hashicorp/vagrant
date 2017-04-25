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

          # If we're running a single command, we modify the params a bit
          if env[:machine_action] == :run_command
            # Use the command that is given to us
            params[:cmd] = env[:run_command]

            # Don't detach, we want to watch the command run
            params[:detach] = false

            # No ports should be shared to the host
            params[:ports] = []

            # Allocate a pty if it was requested
            params[:pty] = true if env[:run_pty]

            # Remove container after execution
            params[:rm] = true if env[:run_rm]

            # Name should be unique
            params[:name] = "#{params[:name]}_#{Time.now.to_i}"

            # We link to our original container
            # TODO
          end

          env[:ui].output(I18n.t("docker_provider.creating"))
          env[:ui].detail("  Name: #{params[:name]}")

          env[:ui].detail(" Image: #{params[:image]}")
          if params[:cmd] && !params[:cmd].empty?
            env[:ui].detail("   Cmd: #{params[:cmd].join(" ")}")
          end
          params[:volumes].each do |volume|
            env[:ui].detail("Volume: #{volume}")
          end
          params[:ports].each do |pair|
            env[:ui].detail("  Port: #{pair}")
          end
          params[:links].each do |name, other|
            env[:ui].detail("  Link: #{name}:#{other}")
          end

          if env[:machine_action] != :run_command
            # For regular "ups" create it and get the CID
            cid = @driver.create(params)
            env[:ui].detail(" \n"+I18n.t(
              "docker_provider.created", id: cid[0...16]))
            @machine.id = cid
          elsif params[:detach]
            env[:ui].detail(" \n"+I18n.t("docker_provider.running_detached"))
          else
            ui_opts = {}

            # If we're running with a pty, we want the output to look as
            # authentic as possible. We don't prefix things and we don't
            # output a newline.
            if env[:run_pty]
              ui_opts[:prefix] = false
              ui_opts[:new_line] = false
            end

            # For run commands, we run it and stream back the output
            env[:ui].detail(" \n"+I18n.t("docker_provider.running")+"\n ")
            @driver.create(params, stdin: env[:run_pty]) do |type, data|
              env[:ui].detail(data.chomp, **ui_opts)
            end
          end

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

          links = []
          @provider_config._links.each do |link|
            parts = link.split(":", 2)
            links << parts
          end

          {
            cmd:        @provider_config.cmd,
            detach:     true,
            env:        @provider_config.env,
            expose:     @provider_config.expose,
            extra_args: @provider_config.create_args,
            hostname:   @machine_config.vm.hostname,
            image:      image,
            links:      links,
            name:       container_name,
            ports:      forwarded_ports(@provider_config.has_ssh),
            privileged: @provider_config.privileged,
            pty:        false,
            volumes:    @provider_config.volumes,
          }
        end

        def forwarded_ports(include_ssh=false)
          mappings = {}
          random = []

          @machine.config.vm.networks.each do |type, options|
            next if type != :forwarded_port

            # Don't include SSH if we've explicitly asked not to
            next if options[:id] == "ssh" && !include_ssh

            # Skip port if it is disabled
            next if options[:disabled]

            # If the guest port is 0, put it in the random group
            if options[:guest] == 0
              random << options[:host]
              next
            end

            mappings["#{options[:host]}/#{options[:protocol]}"] = options
          end

          # Build the results
          result = random.map(&:to_s)
          result += mappings.values.map do |fp|
            protocol = ""
            protocol = "/udp" if fp[:protocol].to_s == "udp"
            host_ip = ""
            host_ip = "#{fp[:host_ip]}:" if fp[:host_ip]
            "#{host_ip}#{fp[:host]}:#{fp[:guest]}#{protocol}"
          end.compact

          result
        end
      end
    end
  end
end
