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
          error_and_exit(<<-error)
The task you're trying to run requires that the vagrant environment
not exist yet, but it appears you already have an instance running
or available. If you really want to rebuild this instance, please
run `vagrant down` first.
error
        end

        VM.execute!(Actions::Up)
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
        Env.persisted_vm.execute!(Actions::Reload)
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

      # Suspend a running vagrant instance. This suspends the instance, saving
      # the state of the VM and "pausing" it. The instance can be resumed
      # again with {resume}.
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def suspend
        Env.load!
        Env.require_persisted_vm
        error_and_exit(<<-error) if Env.persisted_vm.saved?
The vagrant virtual environment you are trying to suspend is already in a
suspended state.
error
        Env.persisted_vm.save_state(true)
      end

      # Resume a running vagrant instance. This resumes an already suspended
      # instance (from {suspend}).
      #
      # This command requires that an instance already be brought up with
      # `vagrant up`.
      def resume
        Env.load!
        Env.require_persisted_vm
        error_and_exit(<<-error) unless Env.persisted_vm.saved?
The vagrant virtual environment you are trying to resume is not in a
suspended state.
error
        Env.persisted_vm.start
      end

      # Export and package the current vm
      #
      # This command requires that an instance be powered off
      def package(name=nil)
        Env.load!
        Env.require_persisted_vm
        error_and_exit(<<-error) unless Env.persisted_vm.powered_off?
The vagrant virtual environment you are trying to package must be powered off
error
        # TODO allow directory specification
        act_on_vm do |vm|
          vm.add_action(Actions::Export)
          vm.add_action(Actions::Package, name || Vagrant.config[:package][:name], FileUtils.pwd)
        end
      end

      def unpackage(name)
        Env.load!
        error_and_exit(<<-error) unless name
Please specify a target package to unpack and import
error

        VM.execute!(Actions::Up, VM.execute!(Actions::Unpackage, name))
      end

      # Manages the `vagrant box` command, allowing the user to add
      # and remove boxes. This single command, given an array, determines
      # which action to take and calls the respective action method
      # (see {box_add} and {box_remove})
      def box(argv)
        sub_commands = ["add", "remove"]

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

      # Adds a box to the local filesystem, given a URI.
      def box_add(name, path)
        Box.execute!(Actions::Box::Add, name, path)
      end

      private

      def act_on_vm(&block)
        yield Env.persisted_vm
        Env.persisted_vm.execute!
      end
    end
  end
end
