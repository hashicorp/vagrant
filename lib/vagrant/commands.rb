module Vagrant
  # Contains all the command-line commands invoked by the
  # binaries. Having them all in one location assists with
  # documentation and also takes the commands out of some of
  # the other classes.
  class Commands
    extend Vagrant::Util

    class <<self
      # TODO: Coming soon to a theatre near you.
      def init

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

        VM.up
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
    end
  end
end