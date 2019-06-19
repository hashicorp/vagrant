require "vagrant/util/hyperv_daemons"

module VagrantPlugins
  module GuestWindows
    module Cap
      class HypervDaemons
        HYPERV_DAEMON_SERVICES = {kvp: "vmickvpexchange", vss: "vmicvss", fcopy: "vmicguestinterface" }

        # https://docs.microsoft.com/en-us/dotnet/api/system.serviceprocess.servicecontrollerstatus?view=netframework-4.8
        STOPPED = 1
        START_PENDING = 2
        STOP_PENDING = 3
        RUNNING =	4
        CONTINUE_PENDING = 5
        PAUSE_PENDING = 6
        PAUSED = 7

        MANUAL_MODE = 3
        DISABLED_MODE = 4

        def self.hyperv_daemons_activate(machine)
          result = HYPERV_DAEMON_SERVICES.keys.map do |service|
            hyperv_daemon_activate machine, service
          end
          result.all?
        end

        def self.hyperv_daemon_activate(machine, service)
          comm = machine.communicate
          service_name = hyperv_service_name(machine, service)
          daemon_service = service_info(comm, service_name)
          return false if daemon_service.nil?

          if daemon_service["StartType"] == DISABLED_MODE
            return false unless enable_service(comm, service_name)
          end

          return false unless restart_service(comm, service_name)
          hyperv_daemon_running machine, service
        end

        def self.hyperv_daemons_running(machine)
          result = HYPERV_DAEMON_SERVICES.keys.map do |service|
            hyperv_daemon_running machine, service.to_sym
          end
          result.all?
        end

        def self.hyperv_daemon_running(machine, service)
          comm = machine.communicate
          service_name = hyperv_service_name(machine, service)
          daemon_service = service_info(comm, service_name)
          return daemon_service["Status"] == RUNNING unless daemon_service.nil?
          false
        end

        def self.hyperv_daemons_installed(machine)
          result = HYPERV_DAEMON_SERVICES.keys.map do |service|
            hyperv_daemon_installed machine, service.to_sym
          end
          result.all?
        end

        def self.hyperv_daemon_installed(machine, service)
          # Windows guest should have Hyper-V service installed
          true
        end

        protected

        def self.service_info(comm, service)
          cmd = "ConvertTo-Json (Get-Service -Name #{service})"
          result = []
          comm.execute(cmd, shell: :powershell) do |type, data|
            if type == :stdout
              result << JSON.parse(data)
            end
          end
          result[0] || {}
        end

        def self.restart_service(comm, service)
          cmd = "Restart-Service -Name #{service} -Force"
          comm.execute(cmd, shell: :powershell)
          true
        end

        def self.enable_service(comm, service)
          cmd = "Set-Service -Name #{service} -StartupType #{MANUAL_MODE}"
          comm.execute(cmd, shell: :powershell)
          true
        end

        def self.hyperv_service_name(machine, service)
          hyperv_daemon_name(service)
        end

        def self.hyperv_daemon_name(service)
          HYPERV_DAEMON_SERVICES[service]
        end
      end
    end
  end
end
