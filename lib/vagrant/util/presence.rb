module Vagrant
  module Util
    module Presence
      extend self

      # Determines if the given object is "present". A String is considered
      # present if the stripped contents are not empty. An Array/Hash is
      # considered present if they have a length of more than 1. "true" is
      # always present and `false` and `nil` are always not present. Any other
      # object is considered to be present.
      #
      # @return [true, false]
      def present?(obj)
        case obj
        when String
          !obj.strip.empty?
        when Symbol
          !obj.to_s.strip.empty?
        when Array
          !obj.compact.empty?
        when Hash
          !obj.empty?
        when TrueClass, FalseClass
          obj
        when NilClass
          false
        when Object
          true
        end
      end

      # Returns the presence of the object. If the object is {present?}, it is
      # returned. Otherwise `false` is returned.
      #
      # @return [Object, false]
      def presence(obj)
        if present?(obj)
          obj
        else
          false
        end
      end
    end
  end
end
