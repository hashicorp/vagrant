require 'optparse'
require "vagrant/util/safe_puts"

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

          variables = {
            host_key: options[:host] || machine.name || "vagrant",
            rdp_port: machine.config.rdp.port,
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
    end
  end
end
