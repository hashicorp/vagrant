require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Delete < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box delete [options] organization/box-name"
              o.separator ""
              o.separator "Deletes box entry on Vagrant Cloud"
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
            if argv.empty? || argv.length > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @env.ui.warn(I18n.t("cloud_command.box.delete_warn", box: argv.first))
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

            box = argv.first.split('/', 2)
            org = box[0]
            box_name = box[1]
            delete_box(org, box_name, options[:username], @client.token)
          end

          def delete_box(org, box_name, username, access_token)
            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(username, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)

            begin
              success = box.delete(org, box_name)
              @env.ui.success(I18n.t("cloud_command.box.delete_success", org: org, box_name: box_name))
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.box.delete_fail", org: org, box_name: box_name))
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
