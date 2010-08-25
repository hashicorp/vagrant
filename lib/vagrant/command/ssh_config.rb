module Vagrant
  module Command
    class SSHConfigCommand < NamedBase
      desc "outputs .ssh/config valid syntax for connecting to this environment via ssh"
      class_option :host, :type => :string, :default => nil, :aliases => "-h"
      register "ssh_config"

      def execute
        raise MultiVMTargetRequired.new("Please specify a single VM to get SSH config info.") if target_vms.length > 1
        vm = target_vms.first
        raise VMNotCreatedError.new("The VM must be created to get the SSH info.") if !vm.created?

        env.ui.info Util::TemplateRenderer.render("ssh_config", {
          :host_key => options[:host] || "vagrant",
          :ssh_user => vm.env.config.ssh.username,
          :ssh_port => vm.ssh.port,
          :private_key_path => vm.env.config.ssh.private_key_path
        })
      end
    end
  end
end
