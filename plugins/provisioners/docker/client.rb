require 'digest/sha1'

module VagrantPlugins
  module DockerProvisioner
    class Client
      def initialize(machine)
        @machine = machine
      end

      def build_images(images)
        @machine.communicate.tap do |comm|
          images.each do |path, opts|
            @machine.ui.info(I18n.t("vagrant.docker_building_single", path: path))
            comm.sudo("docker build #{opts[:args]} #{path}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def pull_images(*images)
        @machine.communicate.tap do |comm|
          images.each do |image|
            @machine.ui.info(I18n.t("vagrant.docker_pulling_single", name: image))
            comm.sudo("docker pull #{image}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def start_service
        if !daemon_running? && @machine.guest.capability?(:docker_start_service)
          @machine.guest.capability(:docker_start_service)
        end
      end

      def daemon_running?
        @machine.guest.capability(:docker_daemon_running)
      end

      def run(containers)
        containers.each do |name, config|
          cids_dir = "/var/lib/vagrant/cids"
          config[:cidfile] ||= "#{cids_dir}/#{Digest::SHA1.hexdigest name}"

          @machine.ui.info(I18n.t("vagrant.docker_running", name: name))
          @machine.communicate.sudo("mkdir -p #{cids_dir}")
          run_container({
            name: name,
            original_name: name,
          }.merge(config))
        end
      end

      def run_container(config)
        raise "Container's cidfile was not provided!" if !config[:cidfile]

        id = "$(cat #{config[:cidfile]})"

        if container_exists?(id)
          if container_args_changed?(config)
            @machine.ui.info(I18n.t("vagrant.docker_restarting_container",
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

      def start_container(id)
        if !container_running?(id)
          @machine.communicate.sudo("docker start #{id}")
        end
      end

      def stop_container(id)
        @machine.communicate.sudo %[
          docker stop #{id}
          docker rm #{id}
        ]
      end

      def container_running?(id)
        lookup_container(id)
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

        @machine.communicate.sudo %[
          rm -f #{config[:cidfile]}
          docker run #{args}
        ]

        name = container_name(config)
        sha  = Digest::SHA1.hexdigest(args)
        container_data_path(config).open("w+") do |f|
          f.write(sha)
        end
      end

      def lookup_container(id, list_all = false)
        docker_ps = "sudo docker ps -q"
        docker_ps << " -a" if list_all
        @machine.communicate.tap do |comm|
          # Docker < 0.7.0 stores container IDs using its short version while
          # recent versions use the full container ID
          # See https://github.com/dotcloud/docker/pull/2140 for more information
          return comm.test("#{docker_ps} | grep -wFq #{id}") ||
            comm.test("#{docker_ps} -notrunc | grep -wFq #{id}")
        end
      end

      def container_name(config)
        name = config[:name]

        # If the name is the automatically assigned name, then
        # replace the "/" with "-" because "/" is not a valid
        # character for a docker container name.
        name = name.gsub("/", "-") if name == config[:original_name]
        name
      end

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
        @machine.data_dir.join("docker-#{name}")
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
