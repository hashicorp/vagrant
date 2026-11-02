# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module UI
    module Reformatter
      def format_message(type, message, **opts)
        message = super
        opts[:style] = type
        [message, opts]
      end
    end

    class Interface
      def self.inherited(klass)
        klass.prepend(Reformatter)
      end
    end

    class Remote < Basic
      attr_reader :client

      def initialize(client)
        super()
        @client = client
        @logger = Log4r::Logger.new("vagrant::ui")
      end

      def clear_line
        @client.clear_line
      end

      def ask(message, **opts)
        opts[:style] ||= :detail
        opts[:echo] = true if !opts.key?(:echo)
        @client.input(message.gsub("%", "%%"), **opts)
      end

      def safe_puts(message, **opts)
        message, extra_opts = message
        opts = {
          new_line: opts[:printer] == :puts,
          style: extra_opts[:style],
          bold: extra_opts[:bold],
          color: extra_opts[:color]
        }

        client.output(message.gsub("%", "%%"), **opts)
      end

      def machine(type, *data)
        if !client.is_machine_readable
          @logger.info("Machine: #{type} #{data.inspect}")
          return
        end

        opts = {}
        opts = data.pop if data.last.kind_of?(Hash)
        target = opts[:target] || ""

        # Prepare the data by replacing characters that aren't outputted
        data.each_index do |i|
          data[i] = data[i].to_s.dup
          data[i].gsub!(",", "%!(VAGRANT_COMMA)")
          data[i].gsub!("\n", "\\n")
          data[i].gsub!("\r", "\\r")
        end
        table_data = {
          rows: [[Time.now.utc.to_i, target, type, data.join(",")]]
        }

        client.table(table_data, **opts)
      end

      def to_proto
        @client.proto
      end
    end
  end
end
