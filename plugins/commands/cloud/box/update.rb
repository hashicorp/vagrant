require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Update < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box update [options] organization/box-name"
              o.separator ""
              o.separator "Updates a box entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-d", "--description DESCRIPTION", "Full description of the box") do |d|
                options[:description] = d
              end
              o.on("-u", "--username", "The username of the organization that will own the box") do |u|
                options[:username] = u
              end
              o.on("-s", "--short-description DESCRIPTION", "Short description of the box") do |s|
                options[:short_description] = s
              end
              o.on("-p", "--private", "Makes box private") do |p|
                options[:private] = p
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 1 || options.length == 0
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])
            box = argv.first.split('/', 2)

            update_box(box[0], box[1], options, @client.token)
          end

          def update_box(org, box_name, options, access_token)
            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(options[:username], access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, nil, nil, access_token)

            options[:organization] = org
            options[:name] = box_name
            begin
              success = box.update(options)
              @env.ui.success(I18n.t("cloud_command.box.update_success", org: org, box_name: box_name))
              success = success.delete_if{|_, v|v.nil?}
              VagrantPlugins::CloudCommand::Util.format_box_results(success, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.box.update_fail", org: org, box_name: box_name))
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
