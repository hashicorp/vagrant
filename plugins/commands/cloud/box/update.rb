require 'optparse'

module VagrantPlugins
  module CloudCommand
    module BoxCommand
      module Command
        class Update < Vagrant.plugin("2", :command)
          include Util

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
              o.on("-s", "--short-description DESCRIPTION", "Short description of the box") do |s|
                options[:short] = s
              end
              o.on("-p", "--[no-]private", "Makes box private") do |p|
                options[:private] = p
              end
            end

            # Parse the options
            argv = parse_options(opts)
            return if !argv
            if argv.empty? || argv.length > 1 || options.slice(:description, :short, :private).length == 0
              raise Vagrant::Errors::CLIInvalidUsage,
                help: opts.help.chomp
            end

            @client = client_login(@env)
            org, box_name = argv.first.split('/', 2)

            update_box(org, box_name, @client.token, options.slice(:short, :description, :private))
          end

          # Update an existing box
          #
          # @param [String] org Organization name of box
          # @param [String] box_name Name of box
          # @param [String] access_token User access token
          # @param [Hash] options Options for box filtering
          # @option options [String] :short Short description of box
          # @option options [String] :description Full description of box
          # @option options [Boolean] :private Set box visibility as private
          # @return [Integer]
          def update_box(org, box_name, access_token, options={})
            account = VagrantCloud::Account.new(
              custom_server: api_server_url,
              access_token: access_token
            )
            with_box(account: account, org: org, box: box_name) do |box|
              box.short_description = options[:short] if options.key?(:short)
              box.description = options[:description] if options.key?(:description)
              box.private = options[:private] if options.key?(:private)
              box.save
              @env.ui.success(I18n.t("cloud_command.box.update_success", org: org, box_name: box_name))
              format_box_results(box, @env)
              0
            end
          rescue VagrantCloud::Error => e
            @env.ui.error(I18n.t("cloud_command.errors.box.update_fail", org: org, box_name: box_name))
            @env.ui.error(e.message)
            1
          end
        end
      end
    end
  end
end
