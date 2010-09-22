module Vagrant
  # Represents a "box," which is simply a packaged vagrant environment.
  # Boxes are simply `tar` files which contain an exported VirtualBox
  # virtual machine, at the least. They are created with `vagrant package`
  # and may contain additional files if specified by the creator. This
  # class serves to help manage these boxes, although most of the logic
  # is kicked out to middlewares.
  class Box
    # The name of the box.
    attr_accessor :name

    # The URI for a new box. This is not available for existing boxes.
    attr_accessor :uri

    # The environment which this box belongs to. Although this could
    # actually be many environments, this points to the environment
    # of a specific instance.
    attr_reader :env

    class << self
      # Adds a new box with given name from the given URI. This method
      # begins the process of adding a box from a given URI by setting up
      # the {Box} instance and calling {#add}.
      #
      # @param [String] name The name of the box
      # @param [String] uri URI to the box file
      def add(env, name, uri)
        box = new(env, name)
        box.uri = uri
        box.add
      end
    end

    # Creates a new box instance. Given an optional `name` parameter,
    # newly created instance will have that name, otherwise it defaults
    # to `nil`.
    #
    # **Note:** This method does not actually _create_ the box, but merely
    # returns a new, abstract representation of it. To add a box, see {#add}.
    def initialize(env=nil, name=nil)
      @name = name
      @env = env
    end

    # Returns path to the OVF file of the box. The OVF file is an open
    # virtual machine file which contains specifications of the exported
    # virtual machine this box contains.
    #
    # This will only be valid once the box is imported.
    #
    # @return [String]
    def ovf_file
      directory.join(env.config.vm.box_ovf)
    end

    # Begins the process of adding a box to the vagrant installation. This
    # method requires that `name` and `uri` be set. The logic of this method
    # is kicked out to the `box_add` registered middleware.
    def add
      env.actions.run(:box_add, { "box" => self })
    end

    # Begins the process of destroying this box. This cannot be undone!
    def destroy
      env.actions.run(:box_remove, { "box" => self })
    end

    # Begins sequence to repackage this box.
    def repackage(options=nil)
      env.actions.run(:box_repackage, { "box" => self }.merge(options || {}))
    end

    # Returns the directory to the location of this boxes content in the local
    # filesystem. Note that if the box isn't imported yet, then the path may not
    # yet exist, but still represents where the box will be imported to.
    #
    # @return [String]
    def directory
      env.boxes_path.join(name)
    end

    # Implemented for comparison with other boxes. Comparison is implemented
    # by simply comparing name.
    def <=>(other)
      return super if !other.is_a?(self.class)
      name <=> other.name
    end
  end
end
