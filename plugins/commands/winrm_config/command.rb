require 'optparse'
require "vagrant/util/safe_puts"
require_relative "../../communicators/winrm/helper"

module VagrantPlugins
  module CommandWinRMConfig
    class Command < Vagrant.plugin("2", :command)
      include Vagrant::Util::SafePuts

      def self.synopsis
        "outputs WinRM configuration to connect to the machine"
      end

      def convert_win_paths(paths)
        paths.map! { |path| Vagrant::Util::Platform.format_windows_path(path, :disable_unc) }
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant winrm-config [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--host NAME", "Name the host for the config") do |h|
            options[:host] = h
          end
        end

        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv) do |machine|
          winrm_info = CommunicatorWinRM::Helper.winrm_info(machine)
          raise Vagrant::Errors::WinRMNotRead if winrm_info.nil?

          rdp_info = get_rdp_info(machine) || {}

          variables = {
            host_key: options[:host] || machine.name || "vagrant",
            rdp_host: rdp_info[:host] || winrm_info[:host],
            rdp_port: rdp_info[:port],
            rdp_user: rdp_info[:username],
            rdp_pass: rdp_info[:password],
            winrm_host: winrm_info[:host],
            winrm_port: winrm_info[:port],
            winrm_user: machine.config.winrm.username,
            winrm_password: machine.config.winrm.password
          }

          template = "commands/winrm_config/config"
          config = Vagrant::Util::TemplateRenderer.render(template, variables)
          machine.ui.machine("winrm-config", config)
          safe_puts(config)
          safe_puts
        end

        # Success, exit status 0
        0
      end

      protected

      # Generate RDP information for machine
      #
      # @param [Vagrant::Machine] machine Guest machine
      # @return [Hash, nil]
      def get_rdp_info(machine)
        rdp_info = {}
        if machine.provider.capability?(:rdp_info)
          rdp_info = machine.provider.capability(:rdp_info)
          rdp_info ||= {}
        end

        ssh_info = machine.ssh_info || {}

        if !rdp_info[:username]
          username = ssh_info[:username]
          if machine.config.vm.communicator == :winrm
            username = machine.config.winrm.username
          end
          rdp_info[:username] = username
        end

        if !rdp_info[:password]
          password = ssh_info[:password]
          if machine.config.vm.communicator == :winrm
            password = machine.config.winrm.password
          end
          rdp_info[:password] = password
        end

        rdp_info[:host] ||= ssh_info[:host]
        rdp_info[:port] ||= machine.config.rdp.port
        rdp_info[:username] ||= machine.config.rdp.username

        if rdp_info[:host] == "127.0.0.1"
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
          rdp_info[:port] = port
          return nil if !port
        end

        rdp_info
      end
    end
  end
end
