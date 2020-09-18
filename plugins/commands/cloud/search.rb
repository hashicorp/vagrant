require 'optparse'

module VagrantPlugins
  module CloudCommand
    module Command
      class Search < Vagrant.plugin("2", :command)
        include Util

        def execute
          options = {quiet: true}

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
            o.on("--[no-]auth", "Authenticate with Vagrant Cloud if required before searching") do |l|
              options[:quiet] = !l
            end
          end

          # Parse the options
          argv = parse_options(opts)
          return if !argv
          if argv.length != 1
            raise Vagrant::Errors::CLIInvalidUsage,
              help: opts.help.chomp
          end

          @client = client_login(@env, options.slice(:quiet))
          query = argv.first

          options[:limit] = 25 if !(options[:limit].to_i < 1) && !options[:limit]

          search(query, @client&.token, options)
        end

        # Perform requested search and display results to user
        #
        # @param [String] query Search query string
        # @param [Hash] options
        # @option options [String] :provider Filter by provider
        # @option options [String] :sort Field to sort results
        # @option options [Integer] :limit Number of results to display
        # @option options [Integer] :page Page of results to display
        # @param [String] access_token User access token
        # @return [Integer]
        def search(query, access_token, options={})
          account = VagrantCloud::Account.new(
            custom_server: api_server_url,
            access_token: access_token
          )
          params = {query: query}.merge(options.slice(:provider, :sort, :order, :limit, :page))
          result = account.searcher.search(**params)

          if result.boxes.empty?
            @env.ui.warn(I18n.t("cloud_command.search.no_results", query: query))
            return 0
          end

          format_search_results(result.boxes, options[:short], options[:json], @env)
          0
        rescue VagrantCloud::Error => e
          @env.ui.error(I18n.t("cloud_command.errors.search.fail"))
          @env.ui.error(e.message)
          1
        end
      end
    end
  end
end
