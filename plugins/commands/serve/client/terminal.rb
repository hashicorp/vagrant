module VagrantPlugins
  module CommandServe
    class Client
      class Terminal < Client

        STYLE = {
          detail: "info",
          info: "info",
          output: "output",
          warn: "warning",
          error: "error",
          success: "success",
          header: "header"
        }

        # @return [String] name of proto class
        def self.sdk_alias
          "TerminalUI"
        end

        def input(prompt, **opts)
          client.events(
            [
              SDK::TerminalUI::Event.new(
                input: SDK::TerminalUI::Event::Input.new(
                  prompt: prompt,
                  style: STYLE[:info],
                  secret: !!opts[:echo]
                )
              ),
            ].each
          ).map { |resp|
            resp.input.input
          }.first
        end

        # @param [Array] lines Lines to print
        def output(line, **opts)
          client.events(
            [
              SDK::TerminalUI::Event.new(
                line: SDK::TerminalUI::Event::Line.new(
                  msg: line,
                  style: STYLE[opts[:style]],
                  disable_new_line: !opts[:new_line],
                )
              )
            ].each
          ).each {}
        end
      end
    end
  end
end
