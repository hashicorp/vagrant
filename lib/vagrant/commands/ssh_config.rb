module Vagrant
  class Commands
    # Outputs a valid entry for .ssh/config which can be used to connect
    # to this environment.
    class SSHConfig < Base
      Base.subcommand "ssh-config", self
      description "outputs .ssh/config valid syntax for connecting to this environment via ssh"

      def execute(args=[])
        env.require_root_path

        args = parse_options(args)
        show_single(args[0])
      end

      def show_single(name)
        if name.nil? && env.multivm?
          error_and_exit(:ssh_config_multivm)
          return # for tests
        end

        vm = name.nil? ? env.vms.values.first : env.vms[name.to_sym]
        if vm.nil?
          error_and_exit(:unknown_vm, :vm => name)
          return # for tests
        end

        puts TemplateRenderer.render("ssh_config", {
          :host_key => options[:host] || "vagrant",
          :ssh_user => vm.env.config.ssh.username,
          :ssh_port => vm.ssh.port,
          :private_key_path => vm.env.config.ssh.private_key_path
        })
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant ssh-config [--host NAME]"

        opts.on("-h", "--host [HOST]", "Host name for the SSH config") do |h|
          options[:host] = h
        end
      end
    end
  end
end
