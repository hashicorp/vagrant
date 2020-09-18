require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version delete [options] organization/box-name version"
              o.separator ""
              o.separator "Deletes a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-f", "--[no-]force", "Force deletion without confirmation") do |f|
                options[:force] = f
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.size != 2
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            org, box_name = argv.first.split('/', 2)
            version = argv[1]

            if !options[:force]
              @env.ui.warn(I18n.t("cloud_command.version.delete_warn", version: version, box: argv.first))
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            @client = client_login(@env)

            delete_version(org, box_name, version, @client.token, options.slice)
          end

          # Delete the requested box version
          #
          # @param [String] org Box organization name
          # @param [String] box_name Name of the box
          # @param [String] box_version Version of the box
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options Current unsued
          def delete_version(org, box_name, box_version, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_version(account: account, org: org, box: box_name, version: box_version) do |version|
              version.delete
              @env.ui.success(I18n.t("cloud_command.version.delete_success",
                version: box_version, org: org, box_name: box_name))
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.version.delete_fail",
              version: box_version, org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
