require 'digest/sha1'

module VagrantPlugins
  module ContainerProvisioner
    class Client
      def initialize(machine, container_command)
        @machine = machine
        @container_command =  container_command
      end

      # Build an image given a path to a Dockerfile
      #
      # @param [String] - Path to the Dockerfile to pass to
      #   container build command
      def build_images(images)
        @machine.communicate.tap do |comm|
          images.each do |path, opts|
            @machine.ui.info(I18n.t("vagrant.container_building_single", path: path))
            comm.sudo("#{@container_command} build #{opts[:args]} #{path}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      # Pull image given a list of images
      #
      # @param [String] - Image name
      def pull_images(*images)
        @machine.communicate.tap do |comm|
          images.each do |image|
            @machine.ui.info(I18n.t("vagrant.container_pulling_single", name: image))
            comm.sudo("#{@container_command} pull #{image}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def run(containers)
        containers.each do |name, config|
          cids_dir = "/var/lib/vagrant/cids"
          config[:cidfile] ||= "#{cids_dir}/#{Digest::SHA1.hexdigest name}"

          @machine.ui.info(I18n.t("vagrant.container_running", name: name))
          @machine.communicate.sudo("mkdir -p #{cids_dir}")
          run_container({
            name: name,
            original_name: name,
          }.merge(config))
        end
      end

      # Run a OCI container. If the container does not exist it will be
      # created. If the image is stale it will be recreated and restarted
      def run_container(config)
        raise "Container's cidfile was not provided!" if !config[:cidfile]

        id = "$(cat #{config[:cidfile]})"

        if container_exists?(id)
          if container_args_changed?(config)
            @machine.ui.info(I18n.t("vagrant.container_restarting_container_args",
              name: config[:name],
            ))
            stop_container(id)
            create_container(config)
          elsif container_image_changed?(config)
            @machine.ui.info(I18n.t("vagrant.container_restarting_container_image",
              name: config[:name],
            ))
            stop_container(id)
            create_container(config)
          else
            start_container(id)
          end
        else
          create_container(config)
        end
      end

      def container_exists?(id)
        lookup_container(id, true)
      end

      # Start container
      #
      # @param String - Image id
      def start_container(id)
        if !container_running?(id)
          @machine.communicate.sudo("#{@container_command} start #{id}")
        end
      end

      # Stop and remove container
      #
      # @param String - Image id
      def stop_container(id)
        @machine.communicate.sudo %[
          #{@container_command} stop #{id}
          #{@container_command} rm #{id}
        ]
      end

      def container_running?(id)
        lookup_container(id)
      end

      def container_image_changed?(config)
        # Returns true if there is a container running with the given :name,
        # and the container is not using the latest :image.

        # Here, "<cmd> inspect <container>" returns the id of the image
        # that the container is using. We check that the latest image that
        # has been built with that name (:image)  matches the one that the
        # container is running.
        cmd = ("#{@container_command} inspect --format='{{.Image}}' #{config[:name]} |" +
               " grep $(#{@container_command} images -q #{config[:image]})")
        return !@machine.communicate.test(cmd)
      end

      def container_args_changed?(config)
        path = container_data_path(config)
        return true if !path.exist?

        args = container_run_args(config)
        sha  = Digest::SHA1.hexdigest(args)
        return true if path.read.chomp != sha

        return false
      end

      def create_container(config)
        args = container_run_args(config)

        @machine.communicate.sudo %[rm -f "#{config[:cidfile]}"]
        @machine.communicate.sudo %[#{@container_command} run #{args}]

        sha  = Digest::SHA1.hexdigest(args)
        container_data_path(config).open("w+") do |f|
          f.write(sha)
        end
      end

      # Looks up if a container with a given id exists using the
      # `ps` command. Returns Boolean
      #
      # @param String - Image id
      def lookup_container(id, list_all = false)
        container_ps = "sudo #{@container_command} ps -q"
        container_ps << " -a" if list_all
        @machine.communicate.tap do |comm|
          return comm.test("#{container_ps} --no-trunc | grep -wFq #{id}")
        end
      end

      def container_name(config)
        name = config[:name]

        # If the name is the automatically assigned name, then
        # replace the "/" with "-" because "/" is not a valid
        # character for a container name.
        name = name.gsub("/", "-").gsub(":", "-") if name == config[:original_name]
        name
      end

      # Compiles run arguments to be appended to command string.
      # Returns String
      def container_run_args(config)
        name = container_name(config)

        args = "--cidfile=#{config[:cidfile]} "
        args << "-d " if config[:daemonize]
        args << "--name #{name} " if name && config[:auto_assign_name]
        args << "--restart=#{config[:restart]}" if config[:restart]
        args << " #{config[:args]}" if config[:args]

        "#{args} #{config[:image]} #{config[:cmd]}".strip
      end

      def container_data_path(config)
        name = container_name(config)
        @machine.data_dir.join("#{@container_command}-#{name}")
      end

      protected

      # This handles outputting the communication data back to the UI
      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          # Clear out the newline since we add one
          data = data.chomp
          return if data.empty?

          options = {}
          #options[:color] = color if !config.keep_color

          @machine.ui.info(data.chomp, options)
        end
      end
    end
  end
end
