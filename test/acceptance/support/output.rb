module Acceptance
  # This class helps with matching against output so that every
  # test isn't inherently tied to the output format of Vagrant.
  class Output
    def initialize(text)
      @text = text
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
      @text =~ /^No Vagrant environment detected/
    end

    # Tests that the output contains a specific Vagrant version.
    def version(version)
      @text =~ /^Vagrant version #{version}$/
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
  end
end
