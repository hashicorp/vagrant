require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Show < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box show [options] organization/box-name"
              o.separator ""
              o.separator "Displays a boxes attributes on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |u|
                options[:username] = u
              end
              o.on("--versions VERSION", String, "Display box information for a specific version") do |v|
                options[:version] = v
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 1
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])
            box = argv.first.split('/', 2)

            show_box(box[0], box[1], options, @client.token)
          end

          def show_box(org, box_name, options, access_token)
            username = options[:username]

            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(username, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)

            begin
              success = box.read(org, box_name)

              if options[:version]
                # show *this* version only
                results = success["versions"].select{ |v| v if v["version"] == options[:version] }.first
                if !results
                  @env.ui.warn(I18n.t("cloud_command.box.show_filter_empty", version: options[:version], org: org, box_name: box_name))
                  return 0
                end
              else
                results = success
              end
              results = results.delete_if { |_, v| v.nil? }
              VagrantPlugins::CloudCommand::Util.format_box_results(results, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.box.show_fail", org: org,box_name:box_name))
              @env.ui.error(e)
              return 1
            end
          end
        end
      end
    end
  end
end
