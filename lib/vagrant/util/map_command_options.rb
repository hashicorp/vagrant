module Vagrant
  module Util
    class MapCommandOptions
      # Given a hash map of user specified argments, will generate
      # a list. Set the key to the command flag, and the value to 
      # it's value. If the value is boolean (true), only the flag is
      # added. eg.
      # {a: "opt-a", b: true} -> ["--a", "opt-a", "--b"]
      #
      # @param [Hash]   map of commands
      # @param [String] string prepended to cmd line flags (keys)
      #
      # @return[Array<String>] commands in list form
      def self.map_to_command_options(map, cmd_flag="--")
        opt_list = []
        if map == nil
          return opt_list
        end
        map.each do |k, v|
          # If the value is true (bool) add the key as the cmd flag
          if v.is_a?(TrueClass)
            opt_list.push("#{cmd_flag}#{k}")
          # If the value is a string, add the key as the flag, and value as the flags argument
          elsif v.is_a?(String)
            opt_list.push("#{cmd_flag}#{k}")
            opt_list.push(v)
          end
        end
        return opt_list
      end
    end
  end
end
