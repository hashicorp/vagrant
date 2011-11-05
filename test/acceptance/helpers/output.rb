module Acceptance
  # This class helps with matching against output so that every
  # test isn't inherently tied to the output format of Vagrant.
  class Output
    def initialize(text)
      @text = text
    end

    def box_invalid
      @text =~ /^The box file you're attempting to add is invalid./
    end

    def box_path_doesnt_exist
      @text =~ /^The specified path to a file doesn't exist.$/
    end

    def box_installed(name)
      @text =~ /^foo$/
    end

    def no_boxes
      @text =~ /There are no installed boxes!/
    end

    def is_version?(version)
      @text =~ /^Vagrant version #{version}$/
    end
  end
end
