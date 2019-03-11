require 'optparse'
require "vagrant/util/uploader"

module VagrantPlugins
  module CloudCommand
    module Command
      class Publish < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant cloud publish [options] organization/box-name version provider-name provider-file"
            o.separator ""
            o.separator "Create and release a new Vagrant Box on Vagrant Cloud"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("--box-version VERSION", String, "Version of box to create") do |v|
              options[:box_version] = v
            end
            o.on("--url URL", String, "Remote URL to download this provider") do |u|
              options[:url] = u
            end
            o.on("-d", "--description DESCRIPTION", String, "Full description of box") do |d|
              options[:description] = d
            end
            o.on("--version-description DESCRIPTION", String, "Description of the version to create") do |v|
              options[:version_description] = v
            end
            o.on("-f", "--force", "Disables confirmation to create or update box") do |f|
              options[:force] = f
            end
            o.on("-p", "--private", "Makes box private") do |p|
              options[:private] = p
            end
            o.on("-r", "--release", "Releases box") do |p|
              options[:release] = p
            end
            o.on("-s", "--short-description DESCRIPTION", String, "Short description of the box") do |s|
              options[:short_description] = s
            end
            o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address") do |u|
              options[:username] = u
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv

          if argv.empty? || argv.length > 4 || argv.length < 3
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          box = argv.first.split('/', 2)
          org = box[0]
          box_name = box[1]
          version = argv[1]
          provider_name = argv[2]
          box_file = argv[3]

          if !options[:url] && !File.file?(box_file)
            raise Vagrant::Errors::BoxFileNotExist,
              file: box_file
          end

          @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])

          publish_box(org, box_name, version, provider_name, box_file, options, @client.token)
        end

        def publish_box(org, box_name, version, provider_name, box_file, options, access_token)
          server_url = VagrantPlugins::CloudCommand::Util.api_server_url

          @env.ui.warn(I18n.t("cloud_command.publish.confirm.warn"))

          @env.ui.info(I18n.t("cloud_command.publish.confirm.box", org: org,
                              box_name: box_name, version: version, provider_name: provider_name))
          @env.ui.info(I18n.t("cloud_command.publish.confirm.private")) if options[:private]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.release")) if options[:release]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_url",
                             url: options[:url])) if options[:url]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_description",
                             description: options[:description])) if options[:description]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.box_short_desc",
                             short_description: options[:short_description])) if options[:short_description]
          @env.ui.info(I18n.t("cloud_command.publish.confirm.version_desc",
                             version_description: options[:version_description])) if options[:version_description]

          if !options[:force]
            cont = @env.ui.ask(I18n.t("cloud_command.continue"))
            return 1 if cont.strip.downcase != "y"
          end

          account = VagrantPlugins::CloudCommand::Util.account(org, access_token, server_url)
          box = VagrantCloud::Box.new(account, box_name, nil, options[:short_description], options[:description], access_token)
          cloud_version = VagrantCloud::Version.new(box, version, nil, options[:version_description], access_token)
          provider = VagrantCloud::Provider.new(cloud_version, provider_name, nil, options[:url], org, box_name, access_token)

          ui = Vagrant::UI::Prefixed.new(@env.ui, "cloud")

          begin
            ui.info(I18n.t("cloud_command.publish.box_create"))
            box.create
          rescue VagrantCloud::ClientError => e
            if e.error_code == 422
              ui.warn(I18n.t("cloud_command.publish.update_continue", obj: "Box"))
              box.update(options)
            else
              @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
              @env.ui.error(e)
              return 1
            end
          end

          begin
            ui.info(I18n.t("cloud_command.publish.version_create"))
            cloud_version.create_version
          rescue VagrantCloud::ClientError => e
            if e.error_code == 422
              ui.warn(I18n.t("cloud_command.publish.update_continue", obj: "Version"))
              cloud_version.update
            else
              @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
              @env.ui.error(e)
              return 1
            end
          rescue VagrantCloud::InvalidVersion => e
            @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
            @env.ui.error(e)
            return 1
          end

          begin
            ui.info(I18n.t("cloud_command.publish.provider_create"))
            provider.create_provider
          rescue VagrantCloud::ClientError => e
            if e.error_code == 422
              ui.warn(I18n.t("cloud_command.publish.update_continue", obj: "Provider"))
              provider.update
            else
              @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
              @env.ui.error(e)
              return 1
            end
          end

          begin
            if !options[:url]
              box_file = File.absolute_path(box_file)
              ui.info(I18n.t("cloud_command.publish.upload_provider", file: box_file))
              ul = Vagrant::Util::Uploader.new(provider.upload_url, box_file, ui: @env.ui)
              ul.upload!
            end
            if options[:release]
              ui.info(I18n.t("cloud_command.publish.release"))
              cloud_version.release
            end
            @env.ui.success(I18n.t("cloud_command.publish.complete", org: org, box_name: box_name))
            success = box.read(org, box_name)
            success = success.delete_if{|_, v|v.nil?}
            VagrantPlugins::CloudCommand::Util.format_box_results(success, @env)
            return 0
          rescue Vagrant::Errors::UploaderError, VagrantCloud::ClientError => e
            @env.ui.error(I18n.t("cloud_command.errors.publish.fail", org: org, box_name: box_name))
            @env.ui.error(e)
            return 1
          end
          return 1
        end
      end
    end
  end
end
