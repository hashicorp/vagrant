require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Create < Vagrant.plugin("2", :command)
          def execute
            options = {}

            opts = OptionParser.new do |o|
              o.banner = "Usage: vagrant cloud box create [options] organization/box-name"
              o.separator ""
              o.separator "Creates an empty box entry on Vagrant Cloud"
              o.separator ""
              o.separator "Options:"
              o.separator ""

              o.on("-d", "--description DESCRIPTION", String, "Full description of the box") do |d|
                options[:description] = d
              end
              o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |u|
                options[:username] = u
              end
              o.on("-s", "--short-description DESCRIPTION", String, "Short description of the box") do |s|
                options[:short] = s
              end
              o.on("-p", "--private", "Makes box private") do |p|
                options[:private] = p
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
            org = box[0]
            box_name = box[1]
            create_box(org, box_name, options, @client.token)
          end

          # @param [String] - org
          # @param [String] - box_name
          # @param [Hash] - options
          def create_box(org, box_name, options, access_token)
            server_url = VagrantPlugins::CloudCommand::Util.api_server_url
            account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
            box = VagrantCloud::Box.new(account, box_name, nil, options[:short], options[:description], access_token)

            begin
              success = box.create
              @env.ui.success(I18n.t("cloud_command.box.create_success", org: org, box_name: box_name))
              success = success.delete_if { |_, v| v.nil? }
              VagrantPlugins::CloudCommand::Util.format_box_results(success, @env)
              return 0
            rescue VagrantCloud::ClientError => e
              @env.ui.error(I18n.t("cloud_command.errors.box.create_fail", org: org, box_name: box_name))
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
