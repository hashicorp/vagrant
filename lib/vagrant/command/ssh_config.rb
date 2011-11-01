module Vagrant
  module Command
    class SSHConfigCommand < NamedBase
      class_option :host, :type => :string, :default => nil, :aliases => "-h"
      register "ssh_config", "outputs .ssh/config valid syntax for connecting to this environment via ssh"

      def execute
        raise Errors::MultiVMTargetRequired, :command => "ssh_config" if target_vms.length > 1
        vm = target_vms.first
        raise Errors::VMNotCreatedError if !vm.created?
        raise Errors::VMInaccessible if !vm.vm.accessible?

        # We need to fix the file permissions of the key if they aren't set
        # properly, otherwise if the user attempts to SSH in, it won't work!
        vm.ssh.check_key_permissions(vm.env.config.ssh.private_key_path)

        $stdout.puts(Util::TemplateRenderer.render("ssh_config", {
          :host_key => options[:host] || vm.name || "vagrant",
          :ssh_host => vm.env.config.ssh.host,
          :ssh_user => vm.env.config.ssh.username,
          :ssh_port => vm.ssh.port,
          :private_key_path => vm.env.config.ssh.private_key_path,
          :forward_agent => vm.env.config.ssh.forward_agent,
          :forward_x11   => vm.env.config.ssh.forward_x11,
          :shared_connections => vm.env.config.ssh.shared_connections
        }))
      end
    end
  end
end
