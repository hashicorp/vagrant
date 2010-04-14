module Vagrant
  class Commands
    # Outputs the status of the current environment. This command outputs
    # useful information such as whether or not the environment is created
    # and if its running, suspended, etc.
    class Status < Base
      Base.subcommand "status", self
      description "Shows the status of the current environment."

      def execute(args=[])
        wrap_output do
          if !env.root_path
            puts <<-msg
No vagrant environment detected. Run `vagrant init` to setup a Vagrantfile
in the current directory to get started with Vagrant.
msg
          elsif !env.vm
            puts <<-msg
The environment has not yet been created. Run `vagrant up` to create the
environment.
msg
          else
            additional_msg = ""
            if env.vm.vm.running?
              additional_msg = <<-msg
To stop this VM, you can run `vagrant halt` to shut it down forcefully,
or you can run `vagrant suspend` to simply suspend the virtual machine.
In either case, to restart it again, simply run a `vagrant up`.
msg
            elsif env.vm.vm.saved?
              additional_msg = <<-msg
To resume this VM, simply run `vagrant up`.
msg
            elsif env.vm.vm.powered_off?
              additional_msg = <<-msg
To restart this VM, simply run `vagrant up`.
msg
            end

            if !additional_msg.empty?
              additional_msg.chomp!
              additional_msg = "\n\n#{additional_msg}"
            end

            puts <<-msg
The environment has been created. The status of the current environment's
virtual machine is: "#{env.vm.vm.state}."#{additional_msg}
msg
          end
        end
      end

      def options_spec(opts)
        opts.banner = "Usage: vagrant status"
      end
    end
  end
end