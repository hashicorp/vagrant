require 'fileutils'
require 'archive/tar/minitar'

module Vagrant
  class Action
    module Box
      # Unpackages a downloaded box to a given directory with a given
      # name.
      #
      # # Required Variables
      #
      # * `download.temp_path` - A location for the downloaded box. This is
      #   set by the {Download} action.
      # * `box` - A {Vagrant::Box} object.
      #
      class Unpackage
        attr_reader :box_directory

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env

          setup_box_directory
          decompress

          @app.call(@env)
        end

        def recover(env)
          if File.directory?(box_directory)
            FileUtils.rm_rf(box_directory)
          end
        end

        def setup_box_directory
          raise Errors::BoxAlreadyExists.new(:name => @env["box"].name) if File.directory?(@env["box"].directory)

          FileUtils.mkdir_p(@env["box"].directory)
          @box_directory = @env["box"].directory
        end

        def decompress
          Dir.chdir(@env["box"].directory) do
            @env.ui.info "vagrant.actions.box.unpackage.extracting"
            Archive::Tar::Minitar.unpack(@env["download.temp_path"], @env["box"].directory)
          end
        end
      end
    end
  end
end
