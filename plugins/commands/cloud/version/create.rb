require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Create < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version create [options] organization/box-name version"
              o.separator ""
              o.separator "Creates a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-d", "--description DESCRIPTION", String, "A description for this version") do |d|
                options[:description] = d
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length != 2
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = client_login(@env)
            org, box_name = argv.first.split('/', 2)
            version = argv[1]

            create_version(org, box_name, version, @client.token, options.slice(:description))
          end

          # Create a new version of the box
          #
          # @param [String] org Organization box is within
          # @param [String] box_name Name of box
          # @param [String] box_version Version of box to create
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options
          # @option options [String] :description Description of box version
          # @return [Integer]
          def create_version(org, box_name, box_version, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_box(account: account, org: org, box: box_name) do |box|
              version = box.add_version(box_version)
              version.description = options[:description] if options.key?(:description)
              version.save
              @env.ui.success(I18n.t("cloud_command.version.create_success",
                version: box_version, org: org, box_name: box_name))
              format_box_results(version, @env)
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.version.create_fail",
              version: box_version, org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
