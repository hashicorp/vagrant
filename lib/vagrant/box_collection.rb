module Vagrant
  # Represents a collection of boxes, providing helpful methods for
  # finding boxes.
  class BoxCollection < Array
    attr_reader :env

    def initialize(env)
      super()

      @env = env
      reload!
    end

    # Find a box in the collection by the given name. The name must
    # be a string, for now.
    def find(name)
      each do |box|
        return box if box.name == name
      end

      nil
    end

    # Loads the list of all boxes from the source. This modifies the
    # current array.
    def reload!
      clear

      Dir.open(env.boxes_path) do |dir|
        dir.each do |d|
          next if d == "." || d == ".." || !File.directory?(env.boxes_path.join(d))
          self << Box.new(env, d)
        end
      end
    end
  end
end

