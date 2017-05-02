require 'optparse'

require "vagrant/util/safe_puts"

module VagrantPlugins
  module CommandSSHConfig
    class Command < Vagrant.plugin("2", :command)
      include Vagrant::Util::SafePuts

      def self.synopsis
        "outputs OpenSSH valid configuration to connect to the machine"
      end

      def execute
        options = {}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant ssh-config [options] [name|id]"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--host NAME", "Name the host for the config") do |h|
            options[:host] = h
          end
          o.on("--ignore-down", "Ignore machines not running") do |i|
            options[:ignore_down] = i
          end
        end

        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv) do |machine|
          ssh_info = machine.ssh_info
          hostname = options[:host] || machine.name || "vagrant"

          if ssh_info.nil?
            # doesn't appear to be any common way across providers to distinguish
            # between machines not running and failing to provide ssh info.
            if options[:ignore_down]
              @logger.debug("Ignoring machine '#{hostname}' with no ssh response")
              next
            end
            raise Vagrant::Errors::SSHNotReady if ssh_info.nil?
          end

          variables = {
            host_key: hostname,
            ssh_host: ssh_info[:host],
            ssh_port: ssh_info[:port],
            ssh_user: ssh_info[:username],
            keys_only: ssh_info[:keys_only],
            paranoid: ssh_info[:paranoid],
            private_key_path: ssh_info[:private_key_path],
            log_level: ssh_info[:log_level],
            forward_agent: ssh_info[:forward_agent],
            forward_x11:   ssh_info[:forward_x11],
            proxy_command: ssh_info[:proxy_command],
            ssh_command:   ssh_info[:ssh_command],
            forward_env:   ssh_info[:forward_env],
          }

          # Render the template and output directly to STDOUT
          template = "commands/ssh_config/config"
          config   = Vagrant::Util::TemplateRenderer.render(template, variables)
          machine.ui.machine("ssh-config", config)
          safe_puts(config)
          safe_puts
        end

        # Success, exit status 0
        0
      end
    end
  end
end
