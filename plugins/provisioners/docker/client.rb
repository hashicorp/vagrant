require 'digest/sha1'

module VagrantPlugins
  module Docker
    class Client
      def initialize(machine)
        @machine = machine
      end

      def build_images(images)
        @machine.communicate.tap do |comm|
          images.each do |path, opts|
            @machine.ui.info(I18n.t("vagrant.docker_building_single", path: path))
            comm.sudo("docker build #{opts[:args]} #{path}")
          end
        end
      end

      def pull_images(*images)
        @machine.communicate.tap do |comm|
          images.each do |image|
            @machine.ui.info(I18n.t("vagrant.docker_pulling_single", name: image))
            comm.sudo("docker pull #{image}")
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
            name: name
          }.merge(config))
        end
      end

      def run_container(config)
        raise "Container's cidfile was not provided!" if !config[:cidfile]

        id = "$(cat #{config[:cidfile]})"

        if container_exists?(id)
          start_container(id)
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

      def container_running?(id)
        lookup_container(id)
      end

      def create_container(config)
        args = "--cidfile=#{config[:cidfile]} "
        args << "-d " if config[:daemonize]
        args << "--name #{config[:name]} " if config[:name] && config[:auto_assign_name]
        args << config[:args] if config[:args]
        @machine.communicate.sudo %[
          rm -f #{config[:cidfile]}
          docker run #{args} #{config[:image]} #{config[:cmd]}
        ]
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
    end
  end
end
