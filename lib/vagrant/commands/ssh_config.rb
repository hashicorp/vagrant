module Vagrant
  class Commands
    # Outputs a valid entry for .ssh/config which can be used to connect
    # to this environment.
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