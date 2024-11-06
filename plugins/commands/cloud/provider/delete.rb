# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require 'optparse'

module VagrantPlugins
  module CloudCommand
    module ProviderCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud provider delete [options] organization/box-name provider-name version [architecture]"
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
            if argv.count < 3 || argv.count > 4
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            org, box_name = argv.first.split('/', 2)
            provider_name = argv[1]
            version = argv[2]
            architecture = argv[3]

            @client = client_login(@env)
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: @client.token
            )

            if architecture.nil?
              architecture = select_provider_architecture(account, org, box_name, version, provider_name)
            end

            @env.ui.warn(I18n.t("cloud_command.provider.delete_warn",
              architecture: architecture, provider: provider_name, version: version, box: argv.first))

            if !options[:force]
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            delete_provider(org, box_name, version, provider_name, architecture, account, options)
          end

          def select_provider_architecture(account, org, box, version, provider)
            with_version(account: account, org: org, box: box, version: version) do |box_version|
              list = box_version.providers.map(&:architecture)
              return list.first if list.size == 1

              @env.ui.info(I18n.t("cloud_command.provider.delete_multiple_architectures",
                org: org, box_name: box, provider: provider))
              list.each do |provider_name|
                @env.ui.info(" * #{provider_name}")
              end
              selected = nil
              while selected.nil?
                user_input = @env.ui.ask(I18n.t("cloud_command.provider.delete_architectures_prompt") + " ")
                selected = user_input if list.include?(user_input)
              end

              return selected
            end
          end

          # Delete a provider for the box version
          #
          # @param [String] org Organization name
          # @param [String] box Box name
          # @param [String] version Box version
          # @param [String] provider Provider name
          # @param [String] architecture Architecture of guest
          # @param [VagrantCloud::Account] account VagrantCloud account
          # @param [Hash] options Currently unused
          # @return [Integer]
          def delete_provider(org, box, version, provider, architecture, account, options={})
            with_provider(account: account, org: org, box: box, version: version, provider: provider, architecture: architecture) do |p|
              p.delete
              @env.ui.error(I18n.t("cloud_command.provider.delete_success",
                architecture: architecture, provider: provider, org: org, box_name: box, version: version))
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.provider.delete_fail",
              architecture: architecture, provider: provider, org: org, box_name: box, version: version))
            @env.ui.error(e)
            1
          end
        end
      end
    end
  end
end
