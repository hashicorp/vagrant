module Vagrant
  module Command
    class BoxCommand < GroupBase
      register "box", "Commands to manage system boxes"

      desc "add NAME URI", "Add a box to the system"
      def add(name, uri)
        Box.add(env, name, uri)
      end
    end
  end
end
