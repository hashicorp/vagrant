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
      def init
        rootfile_path = File.join(Dir.pwd, Env::ROOTFILE_NAME)
        if File.exist?(rootfile_path)
          error_and_exit(<<-error)
It looks like this directory is already setup for vagrant! (A #{Env::ROOTFILE_NAME}
already exists.)
error
        end

        # Copy over the rootfile template into this directory
        File.copy(File.join(PROJECT_ROOT, "templates", Env::ROOTFILE_NAME), rootfile_path)
      end

      # Bring up a vagrant instance. This handles everything from importing
      # the base VM, setting up shared folders, forwarded ports, etc to
      # provisioning the instance with chef. {up} also starts the instance,
      # running it in the background.
      def up
        Env.load!

        if Env.persisted_vm
          logger.info "VM already created. Starting VM if its not already running..."
          Env.persisted_vm.start
        else
          Env.require_box
          VM.execute!(Actions::VM::Up)
        end
      end

      # Tear down a vagrant instance. This not only shuts down the instance
      # (if its running), but also deletes it from the system, including the
      # hard disks associated with it.
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def down
        Env.load!
        Env.require_persisted_vm
        Env.persisted_vm.destroy
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
        Env.load!
        Env.require_persisted_vm
        SSH.connect
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
        error_and_exit(<<-error) unless Env.persisted_vm.powered_off?
The vagrant virtual environment you are trying to package must be powered off
error

        Env.persisted_vm.package(out_path, include_files)
      end

      # Manages the `vagrant box` command, allowing the user to add
      # and remove boxes. This single command, given an array, determines
      # which action to take and calls the respective action method
      # (see {box_add} and {box_remove})
      def box(argv)
        Env.load!(:suppress_errors => true)

        sub_commands = ["list", "add", "remove"]

        if !sub_commands.include?(argv[0])
          error_and_exit(<<-error)
Please specify a valid action to take on the boxes, either
`add` or `remove`. Examples:

vagrant box add name uri
vagrant box remove name
error
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
          error_and_exit(<<-error)
The box you're attempting to remove does not exist!
error
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
