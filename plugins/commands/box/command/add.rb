require 'optparse'

require_relative 'download_mixins'

module VagrantPlugins
  module CommandBox
    module Command
      class Add < Vagrant.plugin("2", :command)
        include DownloadMixins

        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box add [options] <name, url, or path>"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-c", "--clean", "Clean any temporary download files") do |c|
              options[:clean] = c
            end

            o.on("-f", "--force", "Overwrite an existing box if it exists") do |f|
              options[:force] = f
            end

            build_download_options(o, options)

            o.on("--location-trusted", "Trust 'Location' header from HTTP redirects and use the same credentials for subsequent urls as for the initial one") do |l|
                options[:location_trusted] = l
            end

            o.on("--provider PROVIDER", String, "Provider the box should satisfy") do |p|
              options[:provider] = p
            end

            o.on("--box-version VERSION", String, "Constrain version of the added box") do |v|
              options[:version] = v
            end

            o.separator ""
            o.separator "The box descriptor can be the name of a box on HashiCorp's Vagrant Cloud,"
            o.separator "or a URL, or a local .box file, or a local .json file containing"
            o.separator "the catalog metadata."
            o.separator ""
            o.separator "The options below only apply if you're adding a box file directly,"
            o.separator "and not using a Vagrant server or a box structured like 'user/box':"
            o.separator ""

            o.on("--checksum CHECKSUM", String, "Checksum for the box") do |c|
              options[:checksum] = c
            end

            o.on("--checksum-type TYPE", String, "Checksum type (md5, sha1, sha256)") do |c|
              options[:checksum_type] = c.to_sym
            end

            o.on("--name BOX", String, "Name of the box") do |n|
              options[:name] = n
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.empty? || argv.length > 2
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          url = argv[0]
          if argv.length == 2
            options[:name] = argv[0]
            url = argv[1]
          end

          @env.action_runner.run(Vagrant::Action.action_box_add, {
            box_url: url,
            box_name: options[:name],
            box_provider: options[:provider],
            box_version: options[:version],
            box_checksum_type: options[:checksum_type],
            box_checksum: options[:checksum],
            box_clean: options[:clean],
            box_force: options[:force],
            box_download_ca_cert: options[:ca_cert],
            box_download_ca_path: options[:ca_path],
            box_client_cert: options[:client_cert],
            box_download_insecure: options[:insecure],
            box_download_location_trusted: options[:location_trusted],
            ui: Vagrant::UI::Prefixed.new(@env.ui, "box"),
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
