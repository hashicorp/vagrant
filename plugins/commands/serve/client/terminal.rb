module VagrantPlugins
  module CommandServe
    class Client
      class Terminal < Client
        # @return [String] name of proto class
        def self.sdk_alias
          "TerminalUI"
        end

        # @param [Array] lines Lines to print
        def output(lines, **opts)
          args = {
            lines: lines,
            disable_new_line: !opts[:new_line],
            style: :error,
          }
          case opts[:style]
          when :detail, :info, :output
            args[:style] = SDK::TerminalUI::OutputRequest::Style::INFO
          when :warn
            args[:style] = SDK::TerminalUI::OutputRequest::Style::WARNING
          when :error
            args[:style] = SDK::TerminalUI::OutputRequest::Style::ERROR
          when :success
            args[:style] = SDK::TerminalUI::OutputRequest::Style::SUCCESS
          end

          client.output(req = SDK::TerminalUI::OutputRequest.new(**args))
        end
      end
    end
  end
end
