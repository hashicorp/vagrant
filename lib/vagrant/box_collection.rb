require 'forwardable'

module Vagrant
  # Represents a collection of boxes, providing helpful methods for
  # finding boxes.
  class BoxCollection
    include Enumerable
    extend Forwardable
    def_delegators :@boxes, :length, :each

    # The directory that the boxes are being searched for.
    attr_reader :directory

    # Initializes the class to search for boxes in the given directory.
    def initialize(directory, action_runner)
      @directory     = directory
      @boxes         = []
      @action_runner = action_runner

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

    # Adds a box to this collection with the given name and located
    # at the given URL.
    def add(name, url)
      raise Errors::BoxAlreadyExists, :name => name if find(name)

      @action_runner.run(:box_add,
                         :box_name => name,
                         :box_url => url,
                         :box_directory => @directory.join(name))
    end

    # Loads the list of all boxes from the source. This modifies the
    # current array.
    def reload!
      @boxes.clear

      Dir.open(@directory) do |dir|
        dir.each do |d|
          next if d == "." || d == ".." || !@directory.join(d).directory?
          @boxes << Box.new(d, @directory.join(d), @action_runner)
        end
      end
    end
  end
end

