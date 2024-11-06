# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Show < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {
              architectures: [],
              providers: [],
              quiet: true,
              versions: [],
            }

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box show [options] organization/box-name"
              o.separator ""
              o.separator "Displays a boxes attributes on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("--architectures ARCH", String, "Filter results by architecture support (can be defined multiple times)") do |a|
                options[:architectures].push(a).uniq!
              end
              o.on("--versions VERSION", String, "Display box information for a specific version (can be defined multiple times)") do |v|
                options[:versions].push(v).uniq!
              end
              o.on("--providers PROVIDER", String, "Filter results by provider support (can be defined multiple times)") do |pv|
                options[:providers].push(pv).uniq!
              end
              o.on("--[no-]auth", "Authenticate with Vagrant Cloud if required before searching") do |l|
                options[:quiet] = !l
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = client_login(@env, options.slice(:quiet))
            org, box_name = argv.first.split('/', 2)

            show_box(org, box_name, @client&.token, options.slice(:architectures, :providers, :versions))
          end

          # Display the requested box to the user
          #
          # @param [String] org Organization name of box
          # @param [String] box_name Name of box
          # @param [String] access_token User access token
          # @param [Hash] options Options for box filtering
          # @option options [String] :versions Specific verisons of box
          # @return [Integer]
          def show_box(org, box_name, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_box(account: account, org: org, box: box_name) do |box|
              list = [box]

              # If specific version(s) provided, filter out the version
              list = list.first.versions.find_all { |v|
                options[:versions].include?(v.version)
              } if !Array(options[:versions]).empty?

              # If specific provider(s) provided, filter out the provider(s)
              list = list.find_all { |item|
                if item.is_a?(VagrantCloud::Box)
                  item.versions.any? { |v|
                    v.providers.any? { |p|
                      options[:providers].include?(p.name)
                    }
                  }
                else
                  item.providers.any? { |p|
                    options[:providers].include?(p.name)
                  }
                end
              } if !Array(options[:providers]).empty?

              list = list.find_all { |item|
                if item.is_a?(VagrantCloud::Box)
                  item.versions.any? { |v|
                    v.providers.any? { |p|
                      options[:architectures].include?(p.architecture)
                    }
                  }
                else
                  item.providers.any? { |p|
                    options[:architectures].include?(p.architecture)
                  }
                end
              } if !Array(options[:architectures]).empty?

              if !list.empty?
                list.each do |b|
                  format_box_results(b, @env, options.slice(:providers, :architectures))
                  @env.ui.output("")
                end
                0
              else
                @env.ui.warn(I18n.t("cloud_command.box.show_filter_empty",
                  org: org,
                  box_name: box_name,
                  architectures: Array(options[:architectures]).empty? ? "N/A" : Array(options[:architectures]).join(", "),
                  providers: Array(options[:providers]).empty? ? "N/A" : Array(options[:providers]).join(", "),
                  versions: Array(options[:versions]).empty? ? "N/A" : Array(options[:versions]).join(", ")
                ))
                1
              end
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.box.show_fail", org: org, box_name:box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
