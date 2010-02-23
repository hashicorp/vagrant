module Vagrant
  class Box < Actions::Runner
    attr_accessor :name
    attr_accessor :uri
    attr_accessor :temp_path

    class <<self
      # Finds a box by the given name
      def find(name)
        return nil unless File.directory?(directory(name))
        new(name)
      end

      def add(name, uri)
        box = new
        box.name = name
        box.uri = uri
        box.add
      end

      def directory(name)
        File.join(Env.boxes_path, name)
      end
    end

    def initialize(name=nil)
      @name = name
    end

    def ovf_file
      File.join(directory, Vagrant.config.vm.box_ovf)
    end

    def add
      execute!(Actions::Box::Add)
    end

    def destroy
      execute!(Actions::Box::Destroy)
    end

    def directory
      self.class.directory(self.name)
    end
  end
end