require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version delete [options] organization/box-name version"
              o.separator ""
              o.separator "Deletes a version entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |u|
                options[:username] = u
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 2
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            version = argv[1]

            @env.ui.warn(I18n.t("cloud_command.version.delete_warn", version: version, box: argv.first))
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

            delete_version(org, box_name, version, options, @client.token)
          end

          def delete_version(org, box_name, box_version, options, access_token)
            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            version = VagrantCloud::Version.new(box, box_version, nil, nil, access_token)

            begin
              success = version.delete
              @env.ui.success(I18n.t("cloud_command.version.delete_success", version: box_version, org: org, box_name: box_name))
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.version.delete_fail", version: box_version, org: org, box_name: box_name))
              @env.ui.error(e)
              return 1
            end
            return 1
          end
        end
      end
    end
  end
end
