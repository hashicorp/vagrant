require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Release < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version release [options] organization/box-name version"
              o.separator ""
              o.separator "Releases a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-f", "--[no-]force", "Release without confirmation") do |f|
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
              @env.ui.warn(I18n.t("cloud_command.version.release_warn", version: argv[1], box: argv.first))
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            @client = client_login(@env)
            org, box_name = argv.first.split('/', 2)
            version = argv[1]

            release_version(org, box_name, version, @client.token, options)
          end

          # Release the box version
          #
          # @param [String] org Organization name
          # @param [String] box_name Box name
          # @param [String] version Version of the box
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options Currently unused
          # @return [Integer]
          def release_version(org, box_name, version, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_version(account: account, org: org, box: box_name, version: version) do |v|
              v.release
              @env.ui.success(I18n.t("cloud_command.version.release_success",
                version: version, org: org, box_name: box_name))
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.version.release_fail",
              version: version, org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
