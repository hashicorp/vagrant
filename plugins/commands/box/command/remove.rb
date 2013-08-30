require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Remove < Vagrant.plugin("2", :command)
        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box remove <name> <provider>"
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          raise Vagrant::Errors::CLIInvalidUsage, :help => opts.help.chomp if argv.length < 1

          if !argv[1]
            # Try to automatically determine the provider.
            providers = []
            @env.boxes.all.each do |name, provider|
              if name == argv[0]
                providers << provider
              end
            end

            if providers.length > 1
              @env.ui.error(
                I18n.t("vagrant.commands.box.remove_must_specify_provider",
                       name: argv[0],
                       providers: providers.join(", ")))
              return 1
            end

            argv[1] = providers[0] || ""
          end

          b = nil
          begin
            b = @env.boxes.find(argv[0], argv[1].to_sym)
          rescue Vagrant::Errors::BoxUpgradeRequired
            @env.boxes.upgrade(argv[0])
            retry
          end

          raise Vagrant::Errors::BoxNotFound, :name => argv[0], :provider => argv[1].to_sym if !b
          @env.ui.info(I18n.t("vagrant.commands.box.removing",
                              :name => argv[0],
                              :provider => argv[1]))
          b.destroy!

          # Success, exit status 0
          0
        end
      end
    end
  end
end
