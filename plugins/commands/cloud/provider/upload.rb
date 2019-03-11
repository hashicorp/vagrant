require 'optparse'
require "vagrant/util/uploader"

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Upload < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider upload [options] organization/box-name provider-name version box-file"
              o.separator ""
              o.separator "Uploads a box file to Vagrant Cloud for a specific provider"
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
            file = argv[3] # path expand

            upload_provider(org, box_name, provider_name, version, file, @client.token, options)
          end

          def upload_provider(org, box_name, provider_name, version, file, access_token, options)
            org = options[:username] if options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)
            cloud_version = VagrantCloud::Version.new(box, version, nil, nil, access_token)
            provider = VagrantCloud::Provider.new(cloud_version, provider_name, nil, nil, org, box_name, access_token)

            ul = Vagrant::Util::Uploader.new(provider.upload_url, file, ui: @env.ui)
            ui = Vagrant::UI::Prefixed.new(@env.ui, "cloud")

            begin
              ui.output(I18n.t("cloud_command.provider.upload", org: org, box_name: box_name, version: version, provider: provider_name))
              ui.info("Upload File: #{file}")

              ul.upload!

              ui.success("Successfully uploaded box '#{org}/#{box_name}' (v#{version}) for '#{provider_name}'")
              return 0
            rescue Vagrant::Errors::UploaderError, VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.provider.upload_fail", provider: provider_name, org: org, box_name: box_name, version: version))
              @env.ui.error(e)
              return 1
            end
          end
        end
      end
    end
  end
end
