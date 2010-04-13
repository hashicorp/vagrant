module Vagrant
  class Commands
    # Reload the environment. This is almost equivalent to the {up} command
    # except that it doesn't import the VM and do the initialize bootstrapping
    # of the instance. Instead, it forces a shutdown (if its running) of the
    # VM, updates the metadata (shared folders, forwarded ports), restarts
    # the VM, and then reruns the provisioning if enabled.
    class SSHConfig < Base
      Base.subcommand "ssh-config", self
      description "outputs .ssh/config valid syntax for connecting to this environment via ssh"

      def execute(args=[])
        env.require_root_path

        parse_options(args)
        puts TemplateRenderer.render("ssh_config", {
          :host_key => options[:host] || "vagrant",
          :ssh_user => env.config.ssh.username,
          :ssh_port => env.ssh.port,
          :private_key_path => env.config.ssh.private_key_path
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