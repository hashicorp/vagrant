module Vagrant
  # This class represents the active list of vagrant virtual
  # machines.
  class ActiveList
    FILENAME = "active.json"

    @@list = nil

    class <<self
      # Parses and returns the list of UUIDs from the active VM
      # JSON file. This will cache the result, which can be reloaded
      # by setting the `reload` parameter to true.
      #
      # @return [Array<String>]
      def list(reload = false)
        return @@list unless @@list.nil? || reload

        @@list ||= []
        return @@list unless File.file?(path)
        File.open(path, "r") do |f|
          @@list = JSON.parse(f.read)
        end

        @@list
      end

      # Returns an array of {Vagrant::VM} objects which are currently
      # active.
      def vms
        list.collect { |uuid| Vagrant::VM.find(uuid) }
      end

      # Returns the path to the JSON file which holds the UUIDs of the
      # active virtual machines managed by Vagrant.
      def path
        File.join(Env.home_path, FILENAME)
      end
    end
  end
end