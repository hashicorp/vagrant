require 'optparse'

module VagrantPlugins
  module CommandRDP
    class Command < Vagrant.plugin('2', :command)
      def self.synopsis
        'connects to machine via RDP'
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = 'Usage: vagrant rdp [options] [name] [-- extra args]'
        end

        # Parse out the extra args to send to the RDP client, which
        # is everything after the "--"
        split_index = @argv.index('--')
        if split_index
          options[:extra_args] = @argv.drop(split_index + 1)
          @argv                = @argv.take(split_index)
        end

        # Parse the options and return if we don't have any target.
        argv = parse_options(opts)
        return unless argv

        # Check if the host even supports RDP
        fail Errors::HostUnsupported unless @env.host.capability?(:rdp_client)

        # Execute RDP if we can
        with_target_vms(argv, single_target: true) do |machine|
          unless machine.communicate.ready?
            fail Vagrant::Errors::VMNotCreatedError
          end

          machine.ui.output(I18n.t('vagrant_rdp.detecting'))
          rdp_info = get_rdp_info(machine)
          fail Errors::RDPUndetected unless rdp_info

          # Extra arguments if we have any
          rdp_info[:extra_args] = options[:extra_args]

          machine.ui.detail(
            "Address: #{rdp_info[:host]}:#{rdp_info[:port]}")
          machine.ui.detail("Username: #{rdp_info[:username]}")

          machine.ui.success(I18n.t('vagrant_rdp.connecting'))
          @env.host.capability(:rdp_client, rdp_info)
        end
      end

      protected

      def get_rdp_info(machine)
        rdp_info = {}
        if machine.provider.capability?(:rdp_info)
          rdp_info = machine.provider.capability(:rdp_info)
          rdp_info ||= {}
        end

        ssh_info = machine.ssh_info

        unless rdp_info[:username]
          username = ssh_info[:username]
          if machine.config.vm.communicator == :winrm
            username = machine.config.winrm.username
          end
          rdp_info[:username] = username
        end

        rdp_info[:host] ||= ssh_info[:host]
        rdp_info[:port] ||= machine.config.rdp.port

        if rdp_info[:host] == '127.0.0.1'
          # We need to find a forwarded port...
          search_port = machine.config.rdp.search_port
          ports       = nil
          if machine.provider.capability?(:forwarded_ports)
            ports = machine.provider.capability(:forwarded_ports)
          else
            ports = {}.tap do |result|
              machine.config.vm.networks.each do |type, netopts|
                next if type != :forwarded_port
                next unless netopts[:host]
                result[netopts[:host]] = netopts[:guest]
              end
            end
          end

          ports = ports.invert
          port  = ports[search_port]
          rdp_info[:port] = port
          return nil unless port
        end

        rdp_info
      end
    end
  end
end
