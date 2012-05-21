module Vagrant
  module Config
    # This is the base class for any configuration versions, and includes
    # the stub methods that configuaration versions must implement. Vagrant
    # supports configuration versioning so that backwards compatibility can be
    # maintained for past Vagrantfiles while newer configurations are added.
    # Vagrant only introduces new configuration versions for major versions
    # of Vagrant.
    class VersionBase
      # Returns an empty configuration object. This can be any kind of object,
      # since it is treated as an opaque value on the other side, used only
      # for things like calling into {merge}.
      #
      # @return [Object]
      def self.init
        raise NotImplementedError
      end

      # Loads the configuration for the given proc and returns a configuration
      # object. The return value is treated as an opaque object, so it can be
      # anything you'd like. The return value is the object that is passed
      # into methods like {merge}, so it should be something you expect.
      #
      # @param [Proc] proc The proc that is to be configured.
      # @return [Object]
      def self.load(proc)
        raise NotImplementedError
      end

      # Merges two configuration objects, returning the merged object.
      # The values of `old` and `new` are the opaque objects returned by
      # {load} or {init}.
      #
      # Once again, the return object is treated as an opaque value by
      # the Vagrant configuration loader, so it can be anything you'd like.
      #
      # @param [Object] old Old configuration object.
      # @param [Object] new New configuration object.
      # @return [Object] The merged configuration object.
      def self.merge(old, new)
        raise NotImplementedError
      end
    end
  end
end
