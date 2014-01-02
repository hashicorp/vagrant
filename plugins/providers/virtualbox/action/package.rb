require 'fileutils'

require 'vagrant/action/general/package'

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class Package < Vagrant::Action::General::Package
        # Doing this so that we can test that the parent is properly
        # called in the unit tests.
        alias_method :general_call, :call
        def call(env)
          # Setup the temporary directory
          @temp_dir = env[:tmp_path].join(Time.now.to_i.to_s)
          env["export.temp_dir"] = @temp_dir
          FileUtils.mkpath(env["export.temp_dir"])

          # Just match up a couple environmental variables so that
          # the superclass will do the right thing. Then, call the
          # superclass
          env["package.directory"] = env["export.temp_dir"]

          general_call(env)

          # Always call recover to clean up the temp dir
          clean_temp_dir
        end

        def recover(env)
          clean_temp_dir
          super
        end

        protected

        def clean_temp_dir
          if @temp_dir && File.exist?(@temp_dir)
            FileUtils.rm_rf(@temp_dir)
          end
        end
      end
    end
  end
end
