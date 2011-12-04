require 'forwardable'

module Vagrant
  # Represents a collection of boxes, providing helpful methods for
  # finding boxes. An instance of this is returned by {Environment#boxes}.
  #
  # # Finding a Box
  #
  # To find a box, use the {#find} method with the name of the box. The name
  # is an exact match search.
  #
  #     env.boxes.find("base") # => #<Vagrant::Box>
  #
  class BoxCollection
    include Enumerable
    extend Forwardable
    def_delegators :@boxes, :length, :each

    # The directory that the boxes are being searched for.
    attr_reader :directory

    # Initializes the class to search for boxes in the given directory.
    def initialize(directory)
      @directory = directory
      @boxes     = []

      reload!
    end

    # Find a box in the collection by the given name. The name must
    # be a string, for now.
    def find(name)
      @boxes.each do |box|
        return box if box.name == name
      end

      nil
    end

    # Loads the list of all boxes from the source. This modifies the
    # current array.
    def reload!
      @boxes.clear

      Dir.open(@directory) do |dir|
        dir.each do |d|
          next if d == "." || d == ".." || !@directory.join(d).directory?
          # TODO: env????
          @boxes << Box.new(env, d)
        end
      end
    end
  end
end

