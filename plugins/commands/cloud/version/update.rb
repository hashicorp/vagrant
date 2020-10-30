require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Update < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version update [options] organization/box-name version"
              o.separator ""
              o.separator "Updates a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-d", "--description DESCRIPTION", "A description for this version") do |d|
                options[:description] = d
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.size != 2
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = client_login(@env)
            org, box_name = argv.first.split('/', 2)
            version = argv[1]

            update_version(org, box_name, version, @client.token, options)
          end

          # Update the version of the box
          # @param [String] org Organization name
          # @param [String] box_name Box name
          # @param [String] version Version of the box
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options
          # @options options [String] :description Description of box version
          # @return [Integer]
          def update_version(org, box_name, box_version, access_token, options)
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_version(account: account, org: org, box: box_name, version: box_version) do |version|
              version.description = options[:description] if options.key?(:description)
              version.save

              @env.ui.success(I18n.t("cloud_command.version.update_success",
                version: box_version, org: org, box_name: box_name))
              format_box_results(version, @env)
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.version.update_fail",
              version: box_version, org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
