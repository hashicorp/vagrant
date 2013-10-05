require "json"

module VagrantPlugins
  module CommandBox
    # This is a helper to deal with the boxes state file that Vagrant
    # uses to track the boxes that have been downloaded.
    class StateFile
      def initialize(path)
        @path = path

        @data = {}
        @data = JSON.parse(@path.read) if @path.exist?
        @data["boxes"] ||= {}
      end

      # Add a downloaded box to the state file.
      #
      # @param [Box] box The Box object that was added
      # @param [String] url The URL from where the box was downloaded
      def add_box(box, url)
        box_key = "#{box.name}-#{box.provider}"

        @data["boxes"][box_key] = {
          "url"           => url,
          "downloaded_at" => Time.now.utc.to_s
        }

        save!
      end

      # Remove a box that has been previously downloaded from the state file.
      #
      # @param [Box] box The box that was removed.
      def remove_box(box)
        box_key = "#{box.name}-#{box.provider}"
        @data["boxes"].delete(box_key)
        save!
      end

      # This saves the state back into the state file.
      def save!
        @path.open("w+") do |f|
          f.write(JSON.dump(@data))
        end
      end
    end
  end
end
