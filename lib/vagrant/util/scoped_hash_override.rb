module Vagrant
  module Util
    # This allows for hash options to be overridden by a scope key
    # prefix. An example speaks best here. Imagine the following hash:
    #
    #     original = {
    #       id: "foo",
    #       mitchellh__id: "bar",
    #       mitchellh__other: "foo"
    #     }
    #
    #     scoped = scoped_hash_override(original, "mitchellh")
    #
    #     scoped == {
    #       id: "bar",
    #       other: "foo"
    #     }
    #
    module ScopedHashOverride
      def scoped_hash_override(original, scope)
        # Convert the scope to a string in case a symbol was given since
        # we use string comparisons for everything.
        scope = scope.to_s

        # Shallow copy the hash for the result
        result = original.dup

        original.each do |key, value|
          parts = key.to_s.split("__", 2)

          # If we don't have the proper parts, then bail
          next if parts.length != 2

          # If this is our scope, then override
          if parts[0] == scope
            result[parts[1].to_sym] = value
          end
        end

        result
      end
    end
  end
end
