require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Revoke < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version revoke [options] organization/box-name version"
              o.separator ""
              o.separator "Revokes a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-f", "--[no-]force", "Force revocation without confirmation") do |f|
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

            if !options[:force]
              @env.ui.warn(I18n.t("cloud_command.version.revoke_warn", version: argv[1], box: argv.first))
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            @client = client_login(@env)
            org, box_name = argv.first.split('/', 2)
            version = argv[1]

            revoke_version(org, box_name, version, @client.token, options)
          end

          # Revoke release of box version
          #
          # @param [String] org Organization name
          # @param [String] box_name Box name
          # @param [String] version Version of the box
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options Currently unused
          # @return [Integer]
          def revoke_version(org, box_name, box_version, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_version(account: account, org: org, box: box_name, version: box_version) do |version|
              version.revoke
              @env.ui.success(I18n.t("cloud_command.version.revoke_success",
                version: box_version, org: org, box_name: box_name))
              format_box_results(version, @env)
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.version.revoke_fail",
              version: box_version, org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
