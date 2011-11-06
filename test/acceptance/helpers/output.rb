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

    # Tests that the output contains a specific Vagrant version.
    def is_version?(version)
      @text =~ /^Vagrant version #{version}$/
    end

    # This checks that the VM with the given `vm_name` has the
    # status of `status`.
    def status(vm_name, status)
      @text =~ /^#{vm_name}\s+#{status}$/
    end
  end
end
