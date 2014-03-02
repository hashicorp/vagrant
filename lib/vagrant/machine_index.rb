require "json"
require "pathname"
require "securerandom"

module Vagrant
  # MachineIndex is able to manage the index of created Vagrant environments
  # in a central location.
  #
  # The MachineIndex stores a mapping of UUIDs to basic information about
  # a machine. The UUIDs are stored with the Vagrant environment and are
  # looked up in the machine index.
  #
  # The MachineIndex stores information such as the name of a machine,
  # the directory it was last seen at, its last known state, etc. Using
  # this information, we can load the entire {Machine} object for a machine,
  # or we can just display metadata if needed.
  #
  # The internal format of the data file is currently JSON in the following
  # structure:
  #
  #   {
  #     "version": 1,
  #     "machines": {
  #       "uuid": {
  #         "name": "foo",
  #         "provider": "vmware_fusion",
  #         "data_path": "/path/to/data/dir",
  #         "vagrantfile_path": "/path/to/Vagrantfile",
  #         "state": "running",
  #         "updated_at": "2014-03-02 11:11:44 +0100"
  #       }
  #     }
  #   }
  #
  class MachineIndex
    # Initializes a MachineIndex at the given file location.
    #
    # @param [Pathname] data_file Path to the file that should be used
    #   to maintain the machine index. This file doesn't have to exist
    #   but this location must be writable.
    def initialize(data_file)
      @data_file = data_file
      @machines  = {}

      if @data_file.file?
        data = nil
        begin
          data = JSON.load(@data_file.read)
        rescue JSON::ParserError
          raise Errors::CorruptMachineIndex, path: data_file.to_s
        end

        if data
          if !data["version"] || data["version"].to_i != 1
            raise Errors::CorruptMachineIndex, path: data_file.to_s
          end

          @machines = data["machines"] || {}
        end
      end
    end

    # Accesses a machine by UUID and returns a {MachineIndex::Entry}
    #
    # @param [String] uuid UUID for the machine to access.
    # @return [MachineIndex::Entry]
    def [](uuid)
      return nil if !@machines[uuid]
      Entry.new(uuid, @machines[uuid].merge("id" => uuid))
    end

    # Creates/updates an entry object and returns the resulting entry.
    #
    # If the entry was new (no UUID), then the UUID will be set on the
    # resulting entry and can be used.
    #
    # @param [Entry] entry
    # @return [Entry]
    def set(entry)
      # Get the struct and update the updated_at attribute
      struct = entry.to_json_struct

      # Set an ID if there isn't one already set
      id     = entry.id
      id     ||= SecureRandom.uuid

      # Store the data
      @machines[id] = struct
      save

      Entry.new(id, struct)
    end

    # Saves the index.
    #
    # This doesn't usually need to be called because {#set} will
    # automatically save as well.
    def save
      @data_file.open("w") do |f|
        f.write(JSON.dump({
          "version"  => 1,
          "machines" => @machines,
        }))
      end
    end

    # An entry in the MachineIndex.
    class Entry
      # The unique ID for this entry. This is _not_ the ID for the
      # machine itself (which is provider-specific and in the data directory).
      #
      # @return [String]
      attr_reader :id

      # The name of the machine.
      #
      # @return [String]
      attr_accessor :name

      # The name of the provider.
      #
      # @return [String]
      attr_accessor :provider

      # The last known state of this machine.
      #
      # @return [String]
      attr_accessor :state

      # The path to the Vagrantfile that manages this machine.
      #
      # @return [Pathname]
      attr_accessor :vagrantfile_path

      # The last time this entry was updated.
      #
      # @return [DateTime]
      attr_reader :updated_at

      # Initializes an entry.
      #
      # The parameter given should be nil if this is being created
      # publicly.
      def initialize(id=nil, raw=nil)
        # Do nothing if we aren't given a raw value. Otherwise, parse it.
        return if !raw

        @id               = id
        @name             = raw["name"]
        @provider         = raw["provider"]
        @state            = raw["state"]
        @vagrantfile_path = Pathname.new(raw["vagrantfile_path"])
        # TODO(mitchellh): parse into a proper datetime
        @updated_at       = raw["updated_at"]
      end

      # Converts to the structure used by the JSON
      def to_json_struct
        {
          "name"             => @name,
          "provider"         => @provider,
          "state"            => @state,
          "vagrantfile_path" => @vagrantfile_path,
          "updated_at"       => @updated_at,
        }
      end
    end
  end
end
