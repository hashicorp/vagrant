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

    # The environment this box collection belongs to
    attr_reader :env

    def initialize(env)
      @env = env
      @boxes = []

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

      Dir.open(env.boxes_path) do |dir|
        dir.each do |d|
          next if d == "." || d == ".." || !File.directory?(env.boxes_path.join(d))
          @boxes << Box.new(env, d)
        end
      end
    end
  end
end

