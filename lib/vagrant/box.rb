module Vagrant
  class Box < Actions::Runner
    attr_accessor :name
    attr_accessor :uri
    attr_accessor :temp_path

    class <<self
      def add(name, uri)
        box = new
        box.name = name
        box.uri = uri
        box.add
      end
    end

    def add
      execute!(Actions::Box::Add)
    end
  end
end