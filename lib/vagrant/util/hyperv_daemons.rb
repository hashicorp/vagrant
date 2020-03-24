module Vagrant
  module Util
    module HypervDaemons
      HYPERV_DAEMON_SERVICES = %i[kvp vss fcopy]

      def hyperv_daemons_activate(machine)
        result = HYPERV_DAEMON_SERVICES.map do |service|
          hyperv_daemon_activate machine, service
        end
        result.all?
      end

      def hyperv_daemon_activate(machine, service)
        comm = machine.communicate
        service_name = hyperv_service_name(machine, service)
        return false unless comm.test("systemctl enable #{service_name}",
                                      sudo: true)

        return false unless comm.test("systemctl restart #{service_name}",
                                      sudo: true)

        hyperv_daemon_running machine, service
      end

      def hyperv_daemons_running(machine)
        result = HYPERV_DAEMON_SERVICES.map do |service|
          hyperv_daemon_running machine, service
        end
        result.all?
      end

      def hyperv_daemon_running(machine, service)
        comm = machine.communicate
        service_name = hyperv_service_name(machine, service)
        comm.test("systemctl -q is-active #{service_name}")
      end

      def hyperv_daemons_installed(machine)
        result = HYPERV_DAEMON_SERVICES.map do |service|
          hyperv_daemon_installed machine, service
        end
        result.all?
      end

      def hyperv_daemon_installed(machine, service)
        comm = machine.communicate
        daemon_name = hyperv_daemon_name(service)
        comm.test("which #{daemon_name}")
      end

      protected

      def hyperv_service_name(machine, service)
        is_deb = machine.communicate.test("which apt-get")
        separator = is_deb ? '-' : '_'
        ['hv', service.to_s, 'daemon'].join separator
      end

      def hyperv_daemon_name(service)
        ['hv', service.to_s, 'daemon'].join '_'
      end
    end
  end
end
