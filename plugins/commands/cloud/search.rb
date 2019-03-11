require 'optparse'

module VagrantPlugins
  module CloudCommand
    module Command
      class Search < Vagrant.plugin("2", :command)
        def execute
          options = {}

          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant cloud search [options] query"
            o.separator ""
            o.separator "Search for boxes managed by a specific"
            o.separator "user/organization on Vagrant Cloud"
            o.separator ""
            o.separator "Options:"
            o.separator ""

            o.on("-j", "--json", "Formats results in JSON") do |j|
              options[:json] = j
            end
            o.on("-p", "--page PAGE", Integer, "The page to display Default: 1") do |j|
              options[:page] = j
            end
            o.on("-s", "--short", "Shows a simple list of box names") do |s|
              options[:short] = s
            end
            o.on("-o", "--order ORDER", String, "Order to display results ('desc' or 'asc') Default: 'desc'") do |o|
              options[:order] = o
            end
            o.on("-l", "--limit LIMIT", Integer, "Max number of search results Default: 25") do |l|
              options[:limit] = l
            end
            o.on("-p", "--provider PROVIDER", String, "Filter search results to a single provider. Defaults to all.") do |p|
              options[:provider] = p
            end
            o.on("--sort-by SORT", "Field to sort results on (created, downloads, updated) Default: downloads") do |s|
              options[:sort] = s
            end
            o.on("-u", "--username USERNAME_OR_EMAIL", String, "Vagrant Cloud username or email address to login with") do |u|
              options[:username] = u
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.length > 1
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          @client = VagrantPlugins::CloudCommand::Util.client_login(@env, options[:username])
          query = argv.first

          options[:limit] = 25 if !(options[:limit].to_i < 1) && !options[:limit]

          search(query, options, @client.token)
        end

        def search(query, options, access_token)
          server_url = VagrantPlugins::CloudCommand::Util.api_server_url
          search = VagrantCloud::Search.new(access_token, server_url)

          begin
            search_results = search.search(query, options[:provider], options[:sort], options[:order], options[:limit], options[:page])
            if !search_results["boxes"].empty?
              VagrantPlugins::CloudCommand::Util.format_search_results(search_results["boxes"], options[:short], options[:json], @env)
            else
              @env.ui.warn(I18n.t("cloud_command.search.no_results", query: query))
            end
            return 0
          rescue VagrantCloud::ClientError => e
            @env.ui.error(I18n.t("cloud_command.errors.search.fail"))
            @env.ui.error(e)
            return 1
          end
          return 1
        end
      end
    end
  end
end
