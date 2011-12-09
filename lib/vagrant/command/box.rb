module Vagrant
  module Command
    class BoxCommand < GroupBase
      register "box", "Commands to manage system boxes"

      desc "add NAME URI", "Add a box to the system"
      def add(name, uri)
        env.boxes.add(name, uri)
      end

      desc "remove NAME", "Remove a box from the system"
      def remove(name)
        b = env.boxes.find(name)
        raise Errors::BoxNotFound, :name => name if !b
        b.destroy
      end

      desc "repackage NAME", "Repackage an installed box into a `.box` file."
      def repackage(name)
        b = env.boxes.find(name)
        raise Errors::BoxNotFound, :name => name if !b
        b.repackage
      end

      desc "list", "Lists all installed boxes"
      def list
        boxes = env.boxes.sort
        return env.ui.warn(I18n.t("vagrant.commands.box.no_installed_boxes"), :prefix => false) if boxes.empty?
        boxes.each { |b| env.ui.info(b.name, :prefix => false) }
      end
    end
  end
end
