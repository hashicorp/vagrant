require 'optparse'

module VagrantPlugins
  module CommandBox
    module Command
      class Add < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant box add <url> [-h]"
            o.separator ""

            o.on("-c", "--clean", "Clean any temporary download files") do |c|
              options[:clean] = c
            end

            o.on("-f", "--force", "Overwrite an existing box if it exists.") do |f|
              options[:force] = f
            end

            o.on("--insecure", "Do not validate SSL certificates") do |i|
              options[:insecure] = i
            end

            o.on("--cacert certfile", String, "CA certificate for SSL download") do |c|
              options[:ca_cert] = c
            end

            o.on("--cert certfile", String,
                 "A client SSL cert, if needed") do |c|
              options[:client_cert] = c
            end

            o.on("--provider VALUE", String, "Provider the box should satisfy") do |p|
              options[:provider] = p
            end

            o.separator ""
            o.separator "The options below only apply if you're adding a box file directly,"
            o.separator "and not using a Vagrant server or a box structured like 'user/box':"
            o.separator ""

            o.on("--checksum VALUE", String, "Checksum for the box") do |c|
              options[:checksum] = c
            end

            o.on("--checksum-type VALUE", String, "Checksum type (md5, sha1, sha256)") do |c|
              options[:checksum_type] = c.to_sym
            end

            o.on("--name VALUE", String, "Name of the box") do |n|
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
            box_checksum_type: options[:checksum_type],
            box_checksum: options[:checksum],
            box_clean: options[:clean],
            box_force: options[:force],
            box_download_ca_cert: options[:ca_cert],
            box_download_client_cert: options[:client_cert],
            box_download_insecure: options[:insecure],
          })

          # Success, exit status 0
          0
        end
      end
    end
  end
end
