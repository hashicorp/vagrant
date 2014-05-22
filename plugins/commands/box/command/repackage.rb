require "fileutils"
require 'optparse'
require "pathname"

module VagrantPlugins
  module CommandBox
    module Command
      class Repackage < Vagrant.plugin("2", :command)
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box repackage <name> <provider> <version>"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length != 3

          box_name     = argv[0]
          box_provider = argv[1].to_sym
          box_version  = argv[2]

          # Verify the box exists that we want to repackage
          box = @env.boxes.find(box_name, box_provider, "= #{box_version}")
          if !box
            raise Vagrant::Errors::BoxNotFoundWithProviderAndVersion,
              name: box_name,
              provider: box_provider.to_s,
              version: box_version
          end

          # Repackage the box
          output_name = @env.vagrantfile.config.package.name || "package.box"
          output_path = Pathname.new(File.expand_path(output_name, FileUtils.pwd))
          box.repackage(output_path)

          # Success, exit status 0
          0
        end
      end
    end
  end
end
