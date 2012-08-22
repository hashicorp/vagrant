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

      # This is called just before configuration loading is complete of
      # a potentially completely-merged value to perform final touch-ups
      # to the configuration, if required.
      #
      # This is an optional method to implement. The default implementation
      # will simply return the same object.
      #
      # This will ONLY be called if this is the version that is being
      # used. In the case that an `upgrade` is called, this will never
      # be called.
      #
      # @param [Object] obj Final configuration object.
      # @param [Object] Finalized configuration object.
      def self.finalize(obj)
        obj
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

      # This is called if a previous version of configuration needs to be
      # upgraded to this version. Each version of configuration should know
      # how to upgrade the version immediately prior to it. This should be
      # a best effort upgrade that makes many assumptions. The goal is for
      # this to work in almost every case, but perhaps with some warnings.
      # The return value for this is a 3-tuple: `[object, warnings, errors]`,
      # where `object` is the upgraded configuration object, `warnings` is
      # an array of warning messages, and `errors` is an array of error
      # messages.
      #
      # @param [Object] old The version of the configuration object just
      #   prior to this one.
      # @return [Array] The 3-tuple result. Please see the above documentation
      #   for more information on the exact structure of this object.
      def self.upgrade(old)
        raise NotImplementedError
      end
    end
  end
end
