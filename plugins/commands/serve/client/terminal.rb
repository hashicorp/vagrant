# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    class Client
      class Terminal < Client

        STYLE = {
          detail: "info",
          info: "info",
          output: "info",
          warn: "warning",
          error: "error",
          success: "success",
          header: "header"
        }

        # @return [String] name of proto class
        def self.sdk_alias
          "TerminalUI"
        end

        def is_interactive
          client.is_interactive(Empty.new).interactive
        end

        def is_machine_readable
          client.is_machine_readable(Empty.new).machine_readable
        end

        def input(prompt, **opts)
          event_resp = client.events(
            [
              SDK::TerminalUI::Event.new(
                input: SDK::TerminalUI::Event::Input.new(
                  prompt: prompt,
                  style: STYLE[:info],
                  secret: !opts[:echo],
                  color: opts[:color]
                )
              ),
            ].each
          )
          event_resp.map { |resp|
            input = resp.input
            if !input.error.nil?
              raise Vagrant::Errors::VagrantRemoteError, msg: input.error.message
            end
            input.input
          }.first
        end

        # @param [Array] lines Lines to print
        def output(line, **opts)
          style = STYLE[opts[:style]]
          if opts[:bold] && style != "header"
            style = "#{style}-bold"
          end

          client.events(
            [
              SDK::TerminalUI::Event.new(
                line: SDK::TerminalUI::Event::Line.new(
                  msg: line,
                  style: style,
                  disable_new_line: !opts[:new_line],
                  color: opts[:color]
                )
              )
            ].each
          ).each {}
        end

        def clear_line
          client.events(
            [
              SDK::TerminalUI::Event.new(
                clear_line: SDK::TerminalUI::Event::ClearLine.new
              )
            ].each
          ).each {}
        end

        # @params [Map] data has the table data for the event. The form of
        # this map is:
        #   { headers: List<string>, rows: List<List<string>> }
        def table(data, **opts)
          rows = data[:rows].map { |r|
            SDK::TerminalUI::Event::TableRow.new(
              entries: r.map { |e|
                SDK::TerminalUI::Event::TableEntry.new(value: e.to_s)
              }
            )
          }
          event_resp = client.events(
            [
              SDK::TerminalUI::Event.new(
                table: SDK::TerminalUI::Event::Table.new(
                  headers: data[:headers],
                  rows: rows
                )
              ),
            ].each
          )

          event_resp.map { |resp|
            input = resp.input
            if !input.error.nil?
              raise Vagrant::Errors::VagrantRemoteError, msg: input.error.message
            end
          }
        end

        def to_ui
          Vagrant::UI::Remote.new(self)
        end
      end
    end
  end
end
