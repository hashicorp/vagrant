require "optparse"

module VagrantPlugins
  module CommandRDP
    class Command < Vagrant.plugin("2", :command)
      def self.synopsis
        "connects to machine via RDP"
      end

      def execute
        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant rdp [options] [name]"
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return if !argv

        # Check if the host even supports RDP
        raise Errors::HostUnsupported if !@env.host.capability?(:rdp_client)

        # Execute RDP if we can
        with_target_vms(argv, single_target: true) do |machine|
          if !machine.communicate.ready?
            raise Vagrant::Errors::VMNotCreatedError
          end

          machine.ui.output(I18n.t("vagrant_rdp.detecting"))
          rdp_info = get_rdp_info(machine)
          raise Errors::RDPUndetected if !rdp_info

          machine.ui.detail(
            "Address: #{rdp_info[:host]}:#{rdp_info[:port]}")
          machine.ui.detail("Username: #{rdp_info[:username]}")

          machine.ui.success(I18n.t("vagrant_rdp.connecting"))
          @env.host.capability(:rdp_client, rdp_info)
        end
      end

      protected

      def get_rdp_info(machine)
        ssh_info = machine.ssh_info
        username = ssh_info[:username]
        if machine.config.vm.communicator == :winrm
          username = machine.config.winrm.username
        end

        host = ssh_info[:host]
        port = machine.config.rdp.port

        if host == "127.0.0.1"
          # We need to find a forwarded port...
          search_port = machine.config.rdp.search_port
          ports       = nil
          if machine.provider.capability?(:forwarded_ports)
            ports = machine.provider.capability(:forwarded_ports)
          else
            ports = {}.tap do |result|
              machine.config.vm.networks.each do |type, netopts|
                next if type != :forwarded_port
                next if !netopts[:host]
                result[netopts[:host]] = netopts[:guest]
              end
            end
          end

          ports = ports.invert
          port  = ports[search_port]
          return nil if !port
        end

        return {
          host: host,
          port: port,
          username: username,
        }
      end
    end
  end
end
