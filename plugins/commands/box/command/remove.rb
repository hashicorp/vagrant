require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Remove < Vagrant.plugin("2", :command)
        def execute
          options = {}
          options[:force] = false

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box remove <name>"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-f", "--force", "Remove without confirmation.") do |f|
              options[:force] = f
            end

            o.on("--provider PROVIDER", String,
                 "The specific provider type for the box to remove") do |p|
              options[:provider] = p
            end

            o.on("--box-version VERSION", String,
                 "The specific version of the box to remove") do |v|
              options[:version] = v
            end

            o.on("--all", "Remove all available versions of the box") do |a|
              options[:all] = a
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.empty? || argv.length > 2
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          if argv.length == 2
            # @deprecated
            @env.ui.warn("WARNING: The second argument to `vagrant box remove`")
            @env.ui.warn("is deprecated. Please use the --provider flag. This")
            @env.ui.warn("feature will stop working in the next version.")
            options[:provider] = argv[1]
          end

          @env.action_runner.run(Vagrant::Action.action_box_remove, {
            box_name:     argv[0],
            box_provider: options[:provider],
            box_version:  options[:version],
            force_confirm_box_remove: options[:force],
            box_remove_all_versions: options[:all],
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
