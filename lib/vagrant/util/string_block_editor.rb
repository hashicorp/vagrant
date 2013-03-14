module Vagrant
  module Util
    # This class modifies strings by creating and managing Vagrant-owned
    # "blocks" via wrapping them in specially formed comments.
    #
    # This is useful when modifying a file that someone else owns and adding
    # automatic entries into it. Example: /etc/exports or some other
    # configuration file.
    #
    # Vagrant marks ownership of a block in the string by wrapping it in
    # VAGRANT-BEGIN and VAGRANT-END comments with a unique ID. Example:
    #
    #     foo
    #     # VAGRANT-BEGIN: id
    #     some contents
    #     created by vagrant
    #     # VAGRANT-END: id
    #
    # The goal of this class is to be able to insert and remove these
    # blocks without modifying anything else in the string.
    #
    # The strings usually come from files but it is up to the caller to
    # manage the file resource.
    class StringBlockEditor
      # The current string value. This is the value that is modified by
      # the methods below.
      #
      # @return [String]
      attr_reader :value

      def initialize(string)
        @value = string
      end

      # This returns the keys (or ids) that are in the string.
      #
      # @return [<Array<String>]
      def keys
        regexp = /^#\s*VAGRANT-BEGIN:\s*(.+?)$\r?\n?(.*)$\r?\n?^#\s*VAGRANT-END:\s(\1)$/m
        @value.scan(regexp).map do |match|
          match[0]
        end
      end

      # This deletes the block with the given key if it exists.
      def delete(key)
        key    = Regexp.quote(key)
        regexp = /^#\s*VAGRANT-BEGIN:\s*#{key}$.*^#\s*VAGRANT-END:\s*#{key}$\r?\n?/m
        @value.gsub!(regexp, "")
      end

      # This gets the value of the block with the given key.
      def get(key)
        key    = Regexp.quote(key)
        regexp = /^#\s*VAGRANT-BEGIN:\s*#{key}$\r?\n?(.*?)\r?\n?^#\s*VAGRANT-END:\s*#{key}$\r?\n?/m
        match  = regexp.match(@value)
        return nil if !match
        match[1]
      end

      # This inserts a block with the given key and value.
      #
      # @param [String] key
      # @param [String] value
      def insert(key, value)
        # Insert the new block into the value
        new_block = <<BLOCK
# VAGRANT-BEGIN: #{key}
#{value.strip}
# VAGRANT-END: #{key}
BLOCK

        @value << new_block
      end
    end
  end
end
