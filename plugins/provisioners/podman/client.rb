require_relative "../docker/client"

module VagrantPlugins
  module PodmanProvisioner
    class Client < VagrantPlugins::DockerProvisioner::Client
      def build_images(images)
        @machine.communicate.tap do |comm|
          images.each do |path, opts|
            @machine.ui.info(I18n.t("vagrant.docker_building_single", path: path))
            comm.sudo("podman build #{opts[:args]} #{path}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def pull_images(*images)
        @machine.communicate.tap do |comm|
          images.each do |image|
            @machine.ui.info(I18n.t("vagrant.docker_pulling_single", name: image))
            comm.sudo("podman pull #{image}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def start_container(id)
        if !container_running?(id)
          @machine.communicate.sudo("podman start #{id}")
        end
      end

      def stop_container(id)
        @machine.communicate.sudo %[
          podman stop #{id}
          podman rm #{id}
        ]
      end

      def container_image_changed?(config)
        # Returns true if there is a container running with the given :name,
        # and the container is not using the latest :image.

        # Here, "podman inspect <container>" returns the id of the image
        # that the container is using. We check that the latest image that
        # has been built with that name (:image)  matches the one that the
        # container is running.
        cmd = ("podman inspect --format='{{.Image}}' #{config[:name]} |" +
               " grep $(podman images -q #{config[:image]})")
        return !@machine.communicate.test(cmd)
      end

      def create_container(config)
        args = container_run_args(config)

        @machine.communicate.sudo %[rm -f "#{config[:cidfile]}"]
        @machine.communicate.sudo %[podman run #{args}]

        sha  = Digest::SHA1.hexdigest(args)
        container_data_path(config).open("w+") do |f|
          f.write(sha)
        end
      end

      def lookup_container(id, list_all = false)
        podman_ps = "sudo podman ps -q"
        podman_ps << " -a" if list_all
        @machine.communicate.tap do |comm|
          # Docker < 0.7.0 stores container IDs using its short version while
          # recent versions use the full container ID
          # using full container ID from now on.
          return comm.test("#{podman_ps} --no-trunc | grep -wFq #{id}")
        end
      end

      def container_data_path(config)
        name = container_name(config)
        @machine.data_dir.join("podman-#{name}")
      end


    end
  end
end
