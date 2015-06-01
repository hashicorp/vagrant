module Vagrant
  module Util
    class Env
      #
      # Execute the given command, removing any Ruby-specific environment
      # variables. This is an "enhanced" version of `Bundler.with_clean_env`,
      # which only removes Bundler-specific values. We need to remove all
      # values, specifically:
      #
      # - _ORIGINAL_GEM_PATH
      # - GEM_PATH
      # - GEM_HOME
      # - GEM_ROOT
      # - BUNDLE_BIN_PATH
      # - BUNDLE_GEMFILE
      # - RUBYLIB
      # - RUBYOPT
      # - RUBY_ENGINE
      # - RUBY_ROOT
      # - RUBY_VERSION
      #
      # This will escape Vagrant's environment entirely, which is required if
      # calling an executable that lives in another Ruby environment. The
      # original environment restored at the end of this call.
      #
      # @param [Proc] block
      #   the block to execute with the cleaned environment
      #
      def self.with_clean_env(&block)
        original = ENV.to_hash

        ENV.delete('_ORIGINAL_GEM_PATH')
        ENV.delete_if { |k,_| k.start_with?('BUNDLE_') }
        ENV.delete_if { |k,_| k.start_with?('GEM_') }
        ENV.delete_if { |k,_| k.start_with?('RUBY') }

        yield
      ensure
        ENV.replace(original.to_hash)
      end
    end
  end
end
