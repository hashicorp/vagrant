require 'optparse'

module VagrantPlugins
  module CloudCommand
    module VersionCommand
      module Command
        class Release < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud version release [options] organization/box-name version"
              o.separator ""
              o.separator "Releases a version entry on Vagrant Cloud"
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

            @env.ui.warn(I18n.t("cloud_command.version.release_warn", version: argv[1], box: argv.first))
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])
            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            version = argv[1]

            release_version(org, box_name, version, @client.token, options)
          end

          def release_version(org, box_name, version, access_token, options)
            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            version = VagrantCloud::Version.new(box, version, nil, nil, access_token)

            begin
              success = version.release
              @env.ui.success(I18n.t("cloud_command.version.release_success", version: version, org: org, box_name: box_name))
              success = success.delete_if{|_, v|v.nil?}
              VagrantPlugins::CloudCommand::Util.format_box_results(success, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.version.release_fail", version: version, org: org, box_name: box_name))
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
