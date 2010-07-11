module Vagrant
  module Hosts
    # Base class representing a host machine. These classes
    # define methods which may have host-specific (Mac OS X, Windows,
    # Linux, etc) behavior. The class is automatically determined by
    # default but may be explicitly set via `config.vagrant.host`.
    class Base
      # The {Environment} which this host belongs to.
      attr_reader :env

      class << self
        # Loads the proper host for the given value. If the value is nil
        # or is the symbol `:detect`, then the host class will be detected
        # using the `RUBY_PLATFORM` constant.
        #
        # @param [Environment] env
        # @param [String] klass
        # @return [Base]
        def load(env, klass)
          klass = detect if klass.nil? || klass == :detect
          return nil if !klass
          return klass.new(env)
        end

        # Detects the proper host class for current platform and returns
        # the class.
        #
        # @return [Class]
        def detect
          # More coming soon
          classes = {
            :darwin => BSD,
            :bsd => BSD
          }

          classes.each do |type, klass|
            return klass if Util::Platform.send("#{type}?")
          end

          nil
        rescue Exception
          nil
        end
      end

      # Initialzes a new host. This method shouldn't be called directly,
      # typically, since it will be called by {Environment#load_host!}
      #
      # @param [Environment] env
      def initialize(env)
        @env = env
      end
    end
  end
end
