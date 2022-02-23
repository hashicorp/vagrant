module Vagrant
  module UI
    class Remote < Basic
      attr_reader :client

      def initialize(client)
        super()
        @client = client
      end

      def clear_line
        # no-op
      end

      # This method handles actually outputting a message of a given type
      # to the console.
      def say(type, message, opts={})
        if !opts.key?(:new_line)
          opts[:new_line] = true
        end
        opts[:style] = type.to_sym
        @client.output(message.gsub("%", "%%"), **opts)
      end

      [:detail, :info, :warn, :error, :output, :success].each do |method|
        class_eval <<-CODE
          def #{method}(message, *args)
            say(#{method.inspect}, message, *args)
          end
        CODE
      end

      def to_proto
        @client.proto
      end
    end
  end
end
