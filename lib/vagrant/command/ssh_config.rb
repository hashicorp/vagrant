module Vagrant
  module Command
    class SSHConfigCommand < NamedBase
      class_option :host, :type => :string, :default => nil, :aliases => "-h"
      register "ssh_config", "outputs .ssh/config valid syntax for connecting to this environment via ssh"

      def execute
        raise Errors::MultiVMTargetRequired, :command => "ssh_config" if target_vms.length > 1
        vm = target_vms.first
        raise Errors::VMNotCreatedError if !vm.created?

        $stdout.puts(Util::TemplateRenderer.render("ssh_config", {
          :host_key => options[:host] || "vagrant",
          :ssh_user => vm.env.config.ssh.username,
          :ssh_port => vm.ssh.port,
          :private_key_path => vm.env.config.ssh.private_key_path
        }))
      end
    end
  end
end
