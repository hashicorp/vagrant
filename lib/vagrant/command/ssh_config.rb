require 'optparse'

module Vagrant
  module Command
    class SSHConfig < Base
      def execute
        options = {}

        opts = OptionParser.new do |opts|
          opts.banner = "Usage: vagrant ssh-config [vm-name] [-h name]"

          opts.separator ""

          opts.on("-h", "--host COMMAND", "Name the host for the config..") do |h|
            options[:host] = h
          end
        end

        argv = parse_options(opts)
        return if !argv

        # SSH-config always requires a target VM
        raise Errors::MultiVMTargetRequired, :command => "ssh_config" if @env.multivm? && !argv[0]

        with_target_vms(argv[0]) do |vm|
          raise Errors::VMNotCreatedError if !vm.created?
          raise Errors::VMInaccessible if !vm.vm.accessible?

          # We need to fix the file permissions of the key if they aren't set
          # properly, otherwise if the user attempts to SSH in, it won't work!
          vm.ssh.check_key_permissions(vm.ssh.private_key_path)

          $stdout.puts(Util::TemplateRenderer.render("ssh_config", {
            :host_key => options[:host] || vm.name || "vagrant",
            :ssh_host => vm.config.ssh.host,
            :ssh_user => vm.config.ssh.username,
            :ssh_port => vm.ssh.port,
            :private_key_path => vm.config.ssh.private_key_path,
            :forward_agent => vm.config.ssh.forward_agent,
            :forward_x11   => vm.config.ssh.forward_x11
          }))
        end
      end
    end
  end
end
