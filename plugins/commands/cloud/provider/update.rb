require 'optparse'

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Update < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider update [options] organization/box-name provider-name version url"
              o.separator ""
              o.separator "Updates a provider entry on Vagrant Cloud"
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
            if argv.empty? || argv.length > 4
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            provider_name = argv[1]
            version = argv[2]
            url = argv[3]

            update_provider(org, box_name, provider_name, version, url, @client.token, options)
          end

          def update_provider(org, box_name, provider_name, version, url, access_token, options)
            if !url
              @env.ui.warn(I18n.t("cloud_command.upload.no_url"))
            end

            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            cloud_version = VagrantCloud::Version.new(box, version, nil, nil, access_token)
            provider = VagrantCloud::Provider.new(cloud_version, provider_name, nil, url, org, box_name, access_token)

            begin
              success = provider.update
              @env.ui.success(I18n.t("cloud_command.provider.update_success", provider:provider_name, org: org, box_name: box_name, version: version))
              success = success.delete_if{|_, v|v.nil?}
              VagrantPlugins::CloudCommand::Util.format_box_results(success, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.provider.update_fail", provider:provider_name, org: org, box_name: box_name, version: version))
              @env.ui.error(e)
              return 1
            end
          end
        end
      end
    end
  end
end
