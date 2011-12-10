module Vagrant
  # Represents a "box," which is simply a packaged vagrant environment.
  # Boxes are simply `tar` files which contain an exported VirtualBox
  # virtual machine, at the least. They are created with `vagrant package`
  # and may contain additional files if specified by the creator. This
  # class serves to help manage these boxes, although most of the logic
  # is kicked out to middlewares.
  class Box
    # The name of the box.
    attr_reader :name

    # The directory where this box is stored
    attr_reader :directory

    # Creates a new box instance. Given an optional `name` parameter,
    # newly created instance will have that name, otherwise it defaults
    # to `nil`.
    #
    # **Note:** This method does not actually _create_ the box, but merely
    # returns a new, abstract representation of it. To add a box, see {#add}.
    def initialize(name, directory, action_runner)
      @name          = name
      @directory     = directory
      @action_runner = action_runner
    end

    # Begins the process of destroying this box. This cannot be undone!
    def destroy
      @action_runner.run(:box_remove, { :box_name => @name, :box_directory => @directory })
    end

    # Begins sequence to repackage this box.
    def repackage(options=nil)
      @action_runner.run(:box_repackage, { :box_name => @name, :box_directory => @directory })
    end

    # Implemented for comparison with other boxes. Comparison is implemented
    # by simply comparing name.
    def <=>(other)
      return super if !other.is_a?(self.class)
      name <=> other.name
    end
  end
end
