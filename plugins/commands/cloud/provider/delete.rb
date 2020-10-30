require 'optparse'

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider delete [options] organization/box-name provider-name version"
              o.separator ""
              o.separator "Deletes a provider entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""
              o.on("-f", "--[no-]force", "Force deletion of box version provider without confirmation") do |f|
                options[:force] = f
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.count != 3
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            org, box_name = argv.first.split('/', 2)
            provider_name = argv[1]
            version = argv[2]

            @env.ui.warn(I18n.t("cloud_command.provider.delete_warn",
              provider: provider_name, version:version, box: argv.first))

            if !options[:force]
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            @client = client_login(@env)

            delete_provider(org, box_name, version, provider_name, @client.token, options)
          end

          # Delete a provider for the box version
          #
          # @param [String] org Organization name
          # @param [String] box Box name
          # @param [String] version Box version
          # @param [String] provider Provider name
          # @param [String] access_token User Vagrant Cloud access token
          # @param [Hash] options Currently unused
          # @return [Integer]
          def delete_provider(org, box, version, provider, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_provider(account: account, org: org, box: box, version: version, provider: provider) do |p|
              p.delete
              @env.ui.error(I18n.t("cloud_command.provider.delete_success",
                provider: provider, org: org, box_name: box, version: version))
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.provider.delete_fail",
              provider: provider, org: org, box_name: box, version: version))
            @env.ui.error(e)
            1
          end
        end
      end
    end
  end
end
