module Vagrant
  # This class represents the active list of vagrant virtual
  # machines.
  class ActiveList
    FILENAME = "active.json"

    @@list = nil

    # The environment this active list belongs to
    attr_accessor :env

    # Creates the instance of the ActiveList, with the given environment
    # if specified
    def initialize(env=nil)
      @env = env
    end

    # Parses and returns the list of UUIDs from the active VM
    # JSON file. This will cache the result, which can be reloaded
    # by setting the `reload` parameter to true.
    #
    # @return [Array<String>]
    def list(reload=false)
      return @list unless @list.nil? || reload

      @list ||= {}
      return @list unless File.file?(path)
      File.open(path, "r") do |f|
        begin
          @list = JSON.parse(f.read)
        rescue Exception
          @list = {}
        end

        # This forces earlier versions of Vagrant to use the new hash
        # format. Clearing out the old data isn't a big deal since it
        # was never used.
        @list = {} unless @list.is_a?(Hash)
      end

      @list
    end

    # Returns an array of UUIDs filtered so each is verified to exist.
    def filter_list
      list.each do |uuid, data|
        list.delete(uuid) unless Vagrant::VM.find(uuid, env)
      end

      list
    end

    # Adds a virtual environment to the list of active virtual machines
    def add(vm)
      list[vm.uuid] = {
        :path => env.root_path,
        :created_at => Time.now.to_i
      }

      save
    end

    # Remove a virtual environment from the list of active virtual machines
    def remove(vm)
      vm = vm.uuid if vm.is_a?(Vagrant::VM)
      list.delete(vm)
      save
    end

    # Persists the list down to the JSON file.
    def save
      File.open(path, "w+") do |f|
        f.write(filter_list.to_json)
      end
    end

    # Returns the path to the JSON file which holds the UUIDs of the
    # active virtual machines managed by Vagrant.
    def path
      File.join(env.home_path, FILENAME)
    end
  end
end