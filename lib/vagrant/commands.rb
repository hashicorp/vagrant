module Vagrant
  # Contains all the command-line commands invoked by the
  # binaries. Having them all in one location assists with
  # documentation and also takes the commands out of some of
  # the other classes.
  class Commands
    extend Vagrant::Util

    class << self
      # Initializes a directory for use with vagrant. This command copies an
      # initial `Vagrantfile` into the current working directory so you can
      # begin using vagrant. The configuration file contains some documentation
      # to get you started.
      def init(default_box=nil)
        rootfile_path = File.join(Dir.pwd, Env::ROOTFILE_NAME)
        if File.exist?(rootfile_path)
          error_and_exit(:rootfile_already_exists)
        end

        # Copy over the rootfile template into this directory
        default_box ||= "base"
        File.open(rootfile_path, 'w+') do |f|
          f.write(TemplateRenderer.render(Env::ROOTFILE_NAME, :default_box => default_box))
        end
      end

      # Outputs the status of the current environment. This command outputs
      # useful information such as whether or not the environment is created
      # and if its running, suspended, etc.
      def status
        env = Environment.load!

        wrap_output do
          if !env.vm
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

      # Bring up a vagrant instance. This handles everything from importing
      # the base VM, setting up shared folders, forwarded ports, etc to
      # provisioning the instance with chef. {up} also starts the instance,
      # running it in the background.
      def up
        env = Environment.load!

        if env.vm
          logger.info "VM already created. Starting VM if its not already running..."
          env.vm.start
        else
          env.require_box
          env.create_vm.execute!(Actions::VM::Up)
        end
      end

      # Tear down a vagrant instance. This not only shuts down the instance
      # (if its running), but also deletes it from the system, including the
      # hard disks associated with it.
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def down
        env = Environment.load!
        env.require_persisted_vm
        env.vm.destroy
      end

      # Reload the environment. This is almost equivalent to the {up} command
      # except that it doesn't import the VM and do the initialize bootstrapping
      # of the instance. Instead, it forces a shutdown (if its running) of the
      # VM, updates the metadata (shared folders, forwarded ports), restarts
      # the VM, and then reruns the provisioning if enabled.
      def reload
        Env.load!
        Env.require_persisted_vm
        Env.persisted_vm.execute!(Actions::VM::Reload)
      end

      # SSH into the vagrant instance. This will setup an SSH connection into
      # the vagrant instance, replacing the running ruby process with the SSH
      # connection.
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def ssh
        env = Environment.load!
        env.require_persisted_vm
        env.ssh.connect
      end

      # Halts a running vagrant instance. This forcibly halts the instance;
      # it is the equivalent of pulling the power on a machine. The instance
      # can be restarted again with {up}.
      #
      # This command requires than an instance already be brought up with
      # `vagrant up`.
      def halt
        Env.load!
        Env.require_persisted_vm
        Env.persisted_vm.execute!(Actions::VM::Halt)
      end

      # Suspend a running vagrant instance. This suspends the instance, saving
      # the state of the VM and "pausing" it. The instance can be resumed
      # again with {resume}.
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def suspend
        Env.load!
        Env.require_persisted_vm
        Env.persisted_vm.suspend
      end

      # Resume a running vagrant instance. This resumes an already suspended
      # instance (from {suspend}).
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def resume
        Env.load!
        Env.require_persisted_vm
        Env.persisted_vm.resume
      end

      # Export and package the current vm
      #
      # This command requires that an instance be powered off
      def package(out_path=nil, include_files=[])
        Env.load!
        Env.require_persisted_vm
        error_and_exit(:vm_power_off_to_package) unless Env.persisted_vm.powered_off?

        Env.persisted_vm.package(out_path, include_files)
      end

      # Manages the `vagrant box` command, allowing the user to add
      # and remove boxes. This single command, given an array, determines
      # which action to take and calls the respective action method
      # (see {box_add} and {box_remove})
      def box(argv)
        Env.load!

        sub_commands = ["list", "add", "remove"]

        if !sub_commands.include?(argv[0])
          error_and_exit(:command_box_invalid)
        end

        send("box_#{argv[0]}", *argv[1..-1])
      end

      # Lists all added boxes
      def box_list
        boxes = Box.all.sort

        wrap_output do
          if !boxes.empty?
            puts "Installed Vagrant Boxes:\n\n"
            boxes.each do |box|
              puts box
            end
          else
            puts "No Vagrant Boxes Added!"
          end
        end
      end

      # Adds a box to the local filesystem, given a URI.
      def box_add(name, path)
        Box.add(name, path)
      end

      # Removes a box.
      def box_remove(name)
        box = Box.find(name)
        if box.nil?
          error_and_exit(:box_remove_doesnt_exist)
          return # for tests
        end

        box.destroy
      end

      private

      def act_on_vm(&block)
        yield Env.persisted_vm
        Env.persisted_vm.execute!
      end
    end
  end
end
