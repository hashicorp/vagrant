require 'optparse'

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider delete [options] organization/box-name provider-name version"
              o.separator ""
              o.separator "Deletes a provider entry on Vagrant Cloud"
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
            if argv.empty? || argv.length > 3
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            provider_name = argv[1]
            version = argv[2]

            @env.ui.warn(I18n.t("cloud_command.provider.delete_warn", provider: provider_name, version:version, box: argv.first))
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

            delete_provider(org, box_name, provider_name, version, @client.token, options)
          end

          def delete_provider(org, box_name, provider_name, version, access_token, options)
            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            cloud_version = VagrantCloud::Version.new(box, version, nil, nil, access_token)
            provider = VagrantCloud::Provider.new(cloud_version, provider_name, nil, nil, nil, nil, access_token)

            begin
              success = provider.delete
              @env.ui.error(I18n.t("cloud_command.provider.delete_success", provider: provider_name, org: org, box_name: box_name, version: version))
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.provider.delete_fail", provider: provider_name, org: org, box_name: box_name, version: version))
              @env.ui.error(e)
              return 1
            end
          end
        end
      end
    end
  end
end
