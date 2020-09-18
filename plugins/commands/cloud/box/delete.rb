require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          include Util

          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box delete [options] organization/box-name"
              o.separator ""
              o.separator "Deletes box entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-f", "--[no-]force", "Do not prompt for deletion confirmation") do |f|
                options[:force] = f
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            if !options[:force]
              @env.ui.warn(I18n.t("cloud_command.box.delete_warn", box: argv.first))
              cont = @env.ui.ask(I18n.t("cloud_command.continue"))
              return 1 if cont.strip.downcase != "y"
            end

            @client = client_login(@env)

            org, box_name = argv.first.split('/', 2)
            delete_box(org, box_name, @client.token)
          end

          # Delete the requested box
          #
          # @param [String] org Organization name of box
          # @param [String] box_name Name of box
          # @param [String] access_token User access token
          # @return [Integer]
          def delete_box(org, box_name, access_token)
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_box(account: account, org: org, box: box_name) do |box|
              box.delete
              @env.ui.success(I18n.t("cloud_command.box.delete_success", org: org, box_name: box_name))
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.box.delete_fail", org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
