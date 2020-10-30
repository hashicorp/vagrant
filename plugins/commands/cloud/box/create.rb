require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Create < Vagrant.plugin("2", :command)
          include Util

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
              o.on("-s", "--short-description DESCRIPTION", String, "Short description of the box") do |s|
                options[:short] = s
              end
              o.on("-p", "--[no-]private", "Makes box private") do |p|
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

            @client = client_login(@env)

            org, box_name = argv.first.split('/', 2)
            create_box(org, box_name, @client.token, options.slice(:description, :short, :private))
          end

          # Create a new box
          #
          # @param [String] org Organization name of box
          # @param [String] box_name Name of box
          # @param [String] access_token User access token
          # @param [Hash] options Options for box filtering
          # @option options [String] :short Short description of box
          # @option options [String] :description Full description of box
          # @option options [Boolean] :private Set box visibility as private
          # @return [Integer]
          def create_box(org, box_name, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            box = account.organization(name: org).add_box(box_name)
            box.short_description = options[:short] if options.key?(:short)
            box.description = options[:description] if options.key?(:description)
            box.private = options[:private] if options.key?(:private)
            box.save

            @env.ui.success(I18n.t("cloud_command.box.create_success", org: org, box_name: box_name))
            format_box_results(box, @env)
            0
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.box.create_fail", org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
