module VagrantPlugins
  module CloudCommand
    module Util
      # @return [String] Vagrant Cloud server URL
      def api_server_url
        if Vagrant.server_url == Vagrant::DEFAULT_SERVER_URL
          return "#{Vagrant.server_url}/api/v1"
        else
          return Vagrant.server_url
        end
      end

      # @param [Vagrant::Environment] env
      # @param [Hash] options
      # @option options [String] :login Username or email
      # @option options [String] :description Description of login usage for token
      # @option options [String] :code 2FA code for login
      # @option options [Boolean] :quiet Do not prompt user
      # @returns [VagrantPlugins::CloudCommand::Client, nil]
      def client_login(env, options={})
        return @_client if defined?(@_client)
        @_client = Client.new(env)
        return @_client if @_client.logged_in?

        # If directed to be quiet, do not continue and
        # just return nil
        return if options[:quiet]

        # Let the user know what is going on.
        env.ui.output(I18n.t("cloud_command.command_header") + "\n")

        # If it is a private cloud installation, show that
        if Vagrant.server_url != Vagrant::DEFAULT_SERVER_URL
          env.ui.output("Vagrant Cloud URL: #{Vagrant.server_url}")
        end

        options = {} if !options
        # Ask for the username
        if options[:login]
          @_client.username_or_email = options[:login]
          env.ui.output("Vagrant Cloud username or email: #{@_client.username_or_email}")
        else
          @_client.username_or_email = env.ui.ask("Vagrant Cloud username or email: ")
        end

        @_client.password = env.ui.ask("Password (will be hidden): ", echo: false)

        description_default = "Vagrant login from #{Socket.gethostname}"
        if !options[:description]
          description = env.ui.ask("Token description (Defaults to #{description_default.inspect}): ")
        else
          description = options[:description]
          env.ui.output("Token description: #{description}")
        end

        description = description_default if description.empty?

        code = nil

        begin
          token = @_client.login(description: description, code: code)
        rescue Errors::TwoFactorRequired
          until code
            code = env.ui.ask("2FA code: ")

            if @_client.two_factor_delivery_methods.include?(code.downcase)
              delivery_method, code = code, nil
              @_client.request_code delivery_method
            end
          end

          retry
        end

        @_client.store_token(token)
        Vagrant::Util::CredentialScrubber.sensitive(token)
        env.ui.success(I18n.t("cloud_command.logged_in"))
        @_client
      end

      # Print search results from Vagrant Cloud to the console
      #
      # @param [Array<VagrantCloud::Box>] search_results Box search results from Vagrant Cloud
      # @param [Boolean] short Print short summary
      # @param [Boolean] json Print output in JSON format
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @return [nil]
      def format_search_results(search_results, short, json, env)
        result = search_results.map do |b|
          {
            name: b.tag,
            version: b.current_version.version,
            downloads: format_downloads(b.downloads.to_s),
            providers: b.current_version.providers.map(&:name).join(", ")
          }
        end

        if short
          result.map { |b| env.ui.info(b[:name]) }
        elsif json
          env.ui.info(result.to_json)
        else
          column_labels = {}
          columns = result.first.keys
          columns.each do |c|
            column_labels[c] = c.to_s.upcase
          end
          print_search_table(env, column_labels, result, [:downloads])
        end
        nil
      end

      # Output box details result from Vagrant Cloud
      #
      # @param [VagrantCloud::Box, VagrantCloud::Box::Version] box Box or box version to display
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @return [nil]
      def format_box_results(box, env)
        if box.is_a?(VagrantCloud::Box)
          info = box_info(box)
        elsif box.is_a?(VagrantCloud::Box::Provider)
          info = version_info(box.version)
        else
          info = version_info(box)
        end

        width = info.keys.map(&:size).max
        info.each do |k, v|
          whitespace = width - k.size
          env.ui.info "#{k}: #{"".ljust(whitespace)} #{v}"
        end
        nil
      end

      # Load box and yield
      #
      # @param [VagrantCloud::Account] account Vagrant Cloud account
      # @param [String] org Organization name
      # @param [String] box Box name
      # @yieldparam [VagrantCloud::Box] box Requested Vagrant Cloud box
      # @yieldreturn [Integer]
      # @return [Integer]
      def with_box(account:, org:, box:)
        org = account.organization(name: org)
        b = org.boxes.detect { |b| b.name == box }
        if !b
          @env.ui.error(I18n.t("cloud_command.box.not_found",
            org: org.username, box_name: box))
          return 1
        end
        yield b
      end

      # Load box version and yield
      #
      # @param [VagrantCloud::Account] account Vagrant Cloud account
      # @param [String] org Organization name
      # @param [String] box Box name
      # @param [String] version Box version
      # @yieldparam [VagrantCloud::Box::Version] version Requested Vagrant Cloud box version
      # @yieldreturn [Integer]
      # @return [Integer]
      def with_version(account:, org:, box:, version:)
        with_box(account: account, org: org, box: box) do |b|
          v = b.versions.detect { |v| v.version == version }
          if !v
            @env.ui.error(I18n.t("cloud_command.version.not_found",
              box_name: box, org: org, version: version))
            return 1
          end
          yield v
        end
      end

      # Load box version and yield
      #
      # @param [VagrantCloud::Account] account Vagrant Cloud account
      # @param [String] org Organization name
      # @param [String] box Box name
      # @param [String] version Box version
      # @param [String] provider Box version provider name
      # @yieldparam [VagrantCloud::Box::Provider] provider Requested Vagrant Cloud box version provider
      # @yieldreturn [Integer]
      # @return [Integer]
      def with_provider(account:, org:, box:, version:, provider:)
        with_version(account: account, org: org, box: box, version: version) do |v|
          p = v.providers.detect { |p| p.name == provider }
          if !p
            @env.ui.error(I18n.t("cloud_command.provider.not_found",
              org: org, box_name: box, version: version, provider_name: provider))
            return 1
          end
          yield p
        end
      end

      protected

      # Extract box information for display
      #
      # @param [VagrantCloud::Box] box Box for extracting information
      # @return [Hash<String,String>]
      def box_info(box)
        Hash.new.tap do |i|
          i["Box"] = box.tag
          i["Description"] = box.description
          i["Private"] = box.private ? "yes" : "no"
          i["Created"] = box.created_at
          i["Updated"] = box.updated_at
          if !box.current_version.nil?
            i["Current Version"] = box.current_version.version
          else
            i["Current Version"] = "N/A"
          end
          i["Versions"] = box.versions.slice(0, 5).map(&:version).join(", ")
          if box.versions.size > 5
            i["Versions"] += " ..."
          end
          i["Downloads"] = format_downloads(box.downloads)
        end
      end

      # Extract version information for display
      #
      # @param [VagrantCloud::Box::Version] version Box version for extracting information
      # @return [Hash<String,String>]
      def version_info(version)
        Hash.new.tap do |i|
          i["Box"] = version.box.tag
          i["Version"] = version.version
          i["Description"] = version.description
          i["Status"] = version.status
          i["Providers"] = version.providers.map(&:name).sort.join(", ")
          i["Created"] = version.created_at
          i["Updated"] = version.updated_at
        end
      end

      # Print table results from search request
      #
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @param [Hash] column_labels A hash of key/value pairs for table labels (i.e. {col1: "COL1"})
      # @param [Array] results An array of hashes representing search resuls
      # @param [Array] to_jrust_keys - List of columns keys to right justify (left justify is defualt)
      # @return [nil]
      # @note Modified from https://stackoverflow.com/a/28685559
      def print_search_table(env, column_labels, results, to_rjust_keys)
        columns = column_labels.each_with_object({}) do |(col,label),h|
          h[col] = {
            label: label,
            width: [results.map { |g| g[col].size }.max, label.size].max
          }
        end

        write_header(env, columns)
        write_divider(env, columns)
        results.each { |h| write_line(env, columns, h, to_rjust_keys) }
        write_divider(env, columns)
      end

      # Write the header for a table
      #
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @param [Array<Hash>] columns List of columns in Hash format with `:label` and `:width` keys
      # @return [nil]
      def write_header(env, columns)
        env.ui.info "| #{ columns.map { |_,g| g[:label].ljust(g[:width]) }.join(' | ') } |"
        nil
      end

      # Write a row divider for a table
      #
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @param [Array<Hash>] columns List of columns in Hash format with `:label` and `:width` keys
      # @return [nil]
      def write_divider(env, columns)
        env.ui.info "+-#{ columns.map { |_,g| "-"*g[:width] }.join("-+-") }-+"
        nil
      end

      # Write a line of content for a table
      #
      # @param [Vagrant::Environment] env Current Vagrant environment
      # @param [Array<Hash>] columns List of columns in Hash format with `:label` and `:width` keys
      # @param [Hash] h Values to print in row
      # @param [Array<String>] to_rjust_keys List of columns to right justify
      # @return [nil]
      def write_line(env, columns, h, to_rjust_keys)
        str = h.keys.map { |k|
          if to_rjust_keys.include?(k)
            h[k].rjust(columns[k][:width])
          else
            h[k].ljust(columns[k][:width])
          end
        }.join(" | ")
        env.ui.info "| #{str} |"
        nil
      end

      # Converts a string of numbers into a formatted number
      #
      # 1234 -> 1,234
      #
      # @param [String] number Numer to format
      def format_downloads(number)
        number.to_s.chars.reverse.each_slice(3).map(&:join).join(",").reverse
      end
    end
  end
end
