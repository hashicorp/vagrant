require 'optparse'

require 'vagrant/util/install_cli_autocomplete'

module VagrantPlugins
  module CommandAutocomplete
    module Command
      class Install < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant autocomplete install [-h]"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if argv.length > 0

          written_paths = Vagrant::Util::InstallCLIAutocomplete.install
          if written_paths && written_paths.length > 0
            @env.ui.info(I18n.t("vagrant.autocomplete.installed", paths: written_paths.join("\n- ")))
          else
            @env.ui.info(I18n.t("vagrant.autocomplete.not_installed"))
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
