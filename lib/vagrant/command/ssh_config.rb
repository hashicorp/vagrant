require 'optparse'

require "vagrant/util/safe_puts"

module Vagrant
  module Command
    class SSHConfig < Base
      include Util::SafePuts

      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant ssh-config [vm-name] [--host name]"

          opts.separator ""

          opts.on("--host NAME", "Name the host for the config..") do |h|
            options[:host] = h
          end
        end

        argv = parse_options(opts)
        return if !argv

        with_target_vms(argv, :single_target => true) do |vm|
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.state == :inaccessible

          ssh_info  = vm.ssh.info
          variables = {
            :host_key => options[:host] || vm.name || "vagrant",
            :ssh_host => ssh_info[:host],
            :ssh_port => ssh_info[:port],
            :ssh_user => ssh_info[:username],
            :private_key_path => ssh_info[:private_key_path],
            :forward_agent => ssh_info[:forward_agent],
            :forward_x11   => ssh_info[:forward_x11]
          }

          # Render the template and output directly to STDOUT
          template = "commands/ssh_config/config"
          safe_puts(Util::TemplateRenderer.render(template, variables))
        end

        # Success, exit status 0
        0
       end
    end
  end
end
