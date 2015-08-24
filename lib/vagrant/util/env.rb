require "bundler"

module Vagrant
  module Util
    class Env
      def self.with_original_env
        original_env = ENV.to_hash
        ENV.replace(::Bundler::ORIGINAL_ENV) if defined?(::Bundler::ORIGINAL_ENV)
        ENV.update(Vagrant.original_env)
        yield
      ensure
        ENV.replace(original_env.to_hash)
      end

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
      def self.with_clean_env
        with_original_env do
          ENV["MANPATH"] = ENV["BUNDLE_ORIG_MANPATH"]
          ENV.delete_if { |k,_| k[0,7] == "BUNDLE_" }
          if ENV.has_key? "RUBYOPT"
            ENV["RUBYOPT"] = ENV["RUBYOPT"].sub("-rbundler/setup", "")
            ENV["RUBYOPT"] = ENV["RUBYOPT"].sub("-I#{File.expand_path('..', __FILE__)}", "")
          end
          yield
        end
      end
    end
  end
end
