module Acceptance
  # This class helps with matching against output so that every
  # test isn't inherently tied to the output format of Vagrant.
  class Output
    DEFAULT_VM = "default"

    def initialize(text)
      @text = text
    end

    def box_already_exists(name)
      @text =~ /^A box already exists under the name of '#{name}'/
    end

    # Checks that an error message was outputted about the box
    # being added being invalid.
    def box_invalid
      @text =~ /^The box file you're attempting to add is invalid./
    end

    # Checks that an error message was outputted about the path
    # not existing to the box.
    def box_path_doesnt_exist
      @text =~ /^The specified path to a file doesn't exist.$/
    end

    # Tests that the box with given name is installed.
    def box_installed(name)
      @text =~ /^#{name}$/
    end

    # Tests that the output says there are no installed boxes.
    def no_boxes
      @text =~ /There are no installed boxes!/
    end

    # Tests that the output says there is no Vagrantfile, and as such
    # can't do whatever we requested Vagrant to do.
    def no_vagrantfile
      @text =~ /^A Vagrant environment is required/
    end

    # Tests that the output contains a specific Vagrant version.
    def version(version)
      @text =~ /^Vagrant version #{version}$/
    end

    def resume_port_collision
      @text =~ /^This VM cannot be resumed, because the forwarded ports/
    end

    # This checks that the VM with the given `vm_name` has the
    # status of `status`.
    def status(vm_name, status)
      @text =~ /^#{vm_name}\s+#{status}$/
    end

    # This checks that an error message that the VM must be created
    # is shown.
    def error_vm_must_be_created
      @text =~ /^VM must be created/
    end

    # This checks that the warning that the VM is not created is emitted.
    def vm_not_created_warning
      @text =~ /VM not created. Moving on...$/
    end

    # This checks that the VM is destroyed.
    def vm_destroyed
      @text =~ /Destroying VM and associated drives...$/
    end

    # This checks that the "up" output properly contains text showing that
    # it is downloading the box during the up process.
    def up_fetching_box(name, vm=DEFAULT_VM)
      @text =~ /^\[#{vm}\] Box #{name} was not found. Fetching box from specified URL...$/
    end

    # Check that the output shows that the VM was shut down gracefully
    def vm_halt_graceful
      @text =~ /Attempting graceful shutdown of/
    end

    # Output shows a forceful VM shutdown.
    def vm_halt_force
      @text =~ /Forcing shutdown of VM...$/
    end

    # Output shows the VM is in the process of suspending
    def vm_suspending
      @text =~ /Saving VM state and suspending execution...$/
    end
  end
end
