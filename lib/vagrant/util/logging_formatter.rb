# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "vagrant/util/credential_scrubber"
require "log4r/formatter/formatter"

module Vagrant
  module Util
    # Wrapper for logging formatting to provide
    # information scrubbing prior to being written
    # to output target
    class LoggingFormatter < Log4r::BasicFormatter
      # @return [Log4r::PatternFormatter]
      attr_reader :formatter

      # Creates a new formatter wrapper instance.
      #
      # @param [Log4r::Formatter]
      def initialize(formatter)
        @formatter = formatter
      end

      # Format event and scrub output
      def format(event)
        msg = formatter.format(event)
        CredentialScrubber.desensitize(msg)
      end
    end

    class HCLogFormatter < Log4r::BasicFormatter
      MAX_MESSAGE_LENGTH = 4096

      def format(event)
        message = format_object(event.data).
          force_encoding('UTF-8').
          scrub("?")
        if message.length > MAX_MESSAGE_LENGTH
          message = Array.new.tap { |a|
            until message.empty?
              a << "continued..." unless a.empty?
              a << message.slice!(0, MAX_MESSAGE_LENGTH)
            end
          }
        else
          message = [message]
        end

        message.map do |msg|
          d = {
            "@timestamp" => Time.now.strftime("%Y-%m-%dT%H:%M:%S.%6N%:z"),
            "@level" => Log4r::LNAMES[event.level].downcase,
            "@module" => event.fullname.gsub("::", "."),
            "@message" => msg,
          }
          d["@caller"] = event.tracer[0] if event.tracer
          d.to_json + "\n"
        end
      end
    end

    class HCLogOutputter < Log4r::StderrOutputter
      def write(data)
        data.each do |d|
          super(d)
        end
      end
    end
  end
end
