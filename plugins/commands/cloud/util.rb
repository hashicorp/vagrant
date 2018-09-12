module VagrantPlugins
  module CloudCommand
    class Util
      class << self
        # @param [String] username - Vagrant Cloud username
        # @param [String] access_token - Vagrant Cloud Token used to authenticate
        # @param [String] vagrant_cloud_server - Vagrant Cloud server to make API request
        # @return [VagrantCloud::Account]
        def account(username, access_token, vagrant_cloud_server)
          if !defined?(@_account)
            @_account = VagrantCloud::Account.new(username, access_token, vagrant_cloud_server)
          end
          @_account
        end

        def api_server_url
          if Vagrant.server_url == Vagrant::DEFAULT_SERVER_URL
            return "#{Vagrant.server_url}/api/v1"
          else
            return Vagrant.server_url
          end
        end

        # @param [Vagrant::Environment] env
        # @param [Hash] options
        # @returns [VagrantPlugins::CloudCommand::Client]
        def client_login(env, options)
          if !defined?(@_client)
            @_client = Client.new(env)
            return @_client if @_client.logged_in?

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
          @_client
        end

        # ===================================================
        # Modified from https://stackoverflow.com/a/28685559
        # for printing arrays of hashes in formatted tables
        # ===================================================

        # @param [Vagrant::Environment] - env
        # @param [Hash] - column_labels - A hash of key values for table labels (i.e. {:col1=>"COL1", :col2=>"COL2"})
        # @param [Array] - results - An array of hashes
        # @param [Array] - to_jrust_keys - An array of column keys that should be right justified (default is left justified for all columns)
        def print_search_table(env, column_labels, results, to_rjust_keys)
          columns = column_labels.each_with_object({}) { |(col,label),h|
            h[col] = { label: label,
                       width: [results.map { |g| g[col].size }.max, label.size].max
                     }}

          write_header(env, columns)
          write_divider(env, columns)
          results.each { |h| write_line(env, columns, h,to_rjust_keys) }
          write_divider(env, columns)
        end

        def write_header(env, columns)
          env.ui.info "| #{ columns.map { |_,g| g[:label].ljust(g[:width]) }.join(' | ') } |"
        end

        def write_divider(env, columns)
          env.ui.info "+-#{ columns.map { |_,g| "-"*g[:width] }.join("-+-") }-+"
        end

        def write_line(env, columns,h,to_rjust_keys)
          str = h.keys.map { |k|
            if to_rjust_keys.include?(k)
              h[k].rjust(columns[k][:width])
            else
              h[k].ljust(columns[k][:width])
            end
          }.join(" | ")
          env.ui.info "| #{str} |"
        end

        # ===================================================
        # ===================================================

        # Takes a "mostly" flat key=>value hash from Vagrant Cloud
        # and prints its results in a list
        #
        # @param [Hash] - results - A response hash from vagrant cloud
        # @param [Vagrant::Environment] - env
        def format_box_results(results, env)
          # TODO: remove other description fields? Maybe leave "short"?
          results.delete("description_html")

          if results["current_version"]
            versions = results.delete("versions")
            results["providers"] = results["current_version"]["providers"]

            results["old_versions"] = versions.map{ |v| v["version"] }[1..5].join(", ") + "..."
          end


          width = results.keys.map{|k| k.size}.max
          results.each do |k,v|
            if k == "versions"
              v = v.map{ |ver| ver["version"] }.join(", ")
            elsif k == "current_version"
              v = v["version"]
            elsif k == "providers"
              v = v.map{ |p| p["name"] }.join(", ")
            elsif k == "downloads"
              v = format_downloads(v.to_s)
            end

            whitespace = width-k.size
            env.ui.info "#{k}:" + "".ljust(whitespace) + " #{v}"
          end
        end

        # Converts a string of numbers into a formatted number
        #
        # 1234 -> 1,234
        #
        # @param [String] - download_string
        def format_downloads(download_string)
          return download_string.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
        end


        # @param [Array] search_results - Box search results from Vagrant Cloud
        # @param [String,nil] short - determines if short version will be printed
        # @param [String,nil] json - determines if json version will be printed
        # @param [Vagrant::Environment] - env
        def format_search_results(search_results, short, json, env)
          result = []
          search_results.each do |b|
            box = {}
            box = {
              name: b["tag"],
              version: b["current_version"]["version"],
              downloads: format_downloads(b["downloads"].to_s),
              providers: b["current_version"]["providers"].map{ |p| p["name"] }.join(",")
            }
            result << box
          end

          if short
            result.map {|b| env.ui.info(b[:name])}
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
        end
      end
    end
  end
end
