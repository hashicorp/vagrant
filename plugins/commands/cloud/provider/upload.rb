require 'optparse'
require "vagrant/util/uploader"

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Upload < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {direct: true}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider upload [options] organization/box-name provider-name version box-file"
              o.separator ""
              o.separator "Uploads a box file to Vagrant Cloud for a specific provider"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-D", "--[no-]direct", "Upload asset directly to backend storage") do |d|
                options[:direct] = d
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.count != 4
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = client_login(@env)

            org, box_name = argv.first.split('/', 2)
            provider_name = argv[1]
            version = argv[2]
            file = File.expand_path(argv[3])

            upload_provider(org, box_name, version, provider_name, file, @client.token, options)
          end

          # Upload an asset for a box version provider
          #
          # @param [String] org Organization name
          # @param [String] box Box name
          # @param [String] version Box version
          # @param [String] provider Provider name
          # @param [String] file Path to asset
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options
          # @option options [Boolean] :direct Upload directly to backend storage
          # @return [Integer]
          def upload_provider(org, box, version, provider, file, access_token, options)
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )

            with_provider(account: account, org: org, box: box, version: version, provider: provider) do |p|
              p.upload(direct: options[:direct]) do |upload_url|
                m = options[:direct] ? :put : :put
                uploader = Vagrant::Util::Uploader.new(upload_url, file, ui: @env.ui, method: m)
                ui = Vagrant::UI::Prefixed.new(@env.ui, "cloud")
                ui.output(I18n.t("cloud_command.provider.upload",
                  org: org, box_name: box, version: version, provider: provider))
                ui.info("Upload File: #{file}")
                uploader.upload!
                ui.success(I18n.t("cloud_command.provider.upload_success",
                  org: org, box_name: box, version: version, provider: provider))
              end
              0
            end
          rescue Vagrant::Errors::UploaderError, VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.provider.upload_fail",
              provider: provider, org: org, box_name: box, version: version))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
