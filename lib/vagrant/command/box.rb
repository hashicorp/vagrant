module Vagrant
  module Command
    class BoxCommand < GroupBase
      register "box", "Commands to manage system boxes"

      desc "add NAME URI", "Add a box to the system"
      def add(name, uri)
        Box.add(env, name, uri)
      end

      desc "remove NAME", "Remove a box from the system"
      def remove(name)
        b = Box.find(env, name)
        raise BoxNotFound.new("Box '#{name}' could not be found.") if !b
        b.destroy
      end

      desc "repackage NAME", "Repackage an installed box into a `.box` file."
      def repackage(name)
        b = Box.find(env, name)
        raise BoxNotFound.new("Box '#{name}' could not be found.") if !b
        b.repackage
      end

      desc "list", "Lists all installed boxes"
      def list
        # TODO
      end
    end
  end
end
