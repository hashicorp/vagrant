module Vagrant
  module Hosts
    # Base class representing a host machine. These classes
    # define methods which may have host-specific (Mac OS X, Windows,
    # Linux, etc) behavior. The class is automatically determined by
    # default but may be explicitly set via `config.vagrant.host`.
    class Base
      # The {Environment} which this host belongs to.
      attr_reader :env

      # Loads the proper host for the given value. If the value is nil
      # or is the symbol `:detect`, then the host class will be detected
      # using the `RUBY_PLATFORM` constant.
      #
      # @param [Environment] env
      # @param [String] klass
      # @return [Base]
      def self.load(env, klass)
        klass = detect if klass.nil? || klass == :detect
        return nil if !klass
        return klass.new(env)
      end

      # Detects the proper host class for current platform and returns
      # the class.
      #
      # @return [Class]
      def self.detect
        [BSD, Linux].each do |type|
          result = type.distro_dispatch
          return result if result
        end

        nil
      rescue Exception
        nil
      end

      # This must be implemented by subclasses to dispatch to the proper
      # distro-specific class for the host. If this returns nil then it is
      # an invalid host class.
      def self.distro_dispatch
        nil
      end

      # Initialzes a new host. This method shouldn't be called directly,
      # typically, since it will be called by {Environment#load!}.
      #
      # @param [Environment] env
      def initialize(env)
        @env = env
      end

      # Returns true of false denoting whether or not this host supports
      # NFS shared folder setup. This method ideally should verify that
      # NFS is installed.
      #
      # @return [Boolean]
      def nfs?
        false
      end

      # Exports the given hash of folders via NFS. This method will raise
      # an {Vagrant::Action::ActionException} if anything goes wrong.
      #
      # @param [String] ip IP of the guest machine.
      # @param [Hash] folders Shared folders to sync.
      def nfs_export(ip, folders)
      end

      # Cleans up the exports for the current VM.
      def nfs_cleanup
      end
    end
  end
end
