module Vagrant
  module Util
    class SafeEnv
      # This yields an environment hash to change and catches any issues
      # while changing the environment variables and raises a helpful error
      # to end users.
      def self.change_env
        yield ENV
      rescue Errno::EINVAL
        raise Errors::EnvInval
      end
    end
  end
end
