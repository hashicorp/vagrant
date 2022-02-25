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
      end

      def clear_line
        @client.clear_line
      end

      def ask(message, **opts)
        opts[:style] ||= :detail
        @client.input(message.gsub("%", "%%"), **opts)
      end

      def safe_puts(message, **opts)
        message, extra_opts = message
        opts = {
          new_line: opts[:printer] == :puts,
          style: extra_opts[:style],
          bold: extra_opts[:bold]
        }

        client.output(message.gsub("%", "%%"), **opts)
      end

      def to_proto
        @client.proto
      end
    end
  end
end
