module VagrantPlugins
  module Chef
    # Handles loading configuration values from a Chef config file
    class ChefConfig < Hash
      DEFAULT_PATHS = %w[
        ./.chef/knife.rb
        ~/.chef/knife.rb
        /etc/chef/solo.rb
        /etc/chef/client.rb
      ]

      def self.parse(path = nil)
        new(path).parse
      end

      def initialize(path = nil)
        @path = path
      end

      # Parse the file for the path and store symbolicated keys for knife
      # configuration options.
      def parse
        parse_file
        self
      end

      private

      def parse_file
        lines.each { |line| parse_line line }
      end

      def parse_line(line)
        eval line, scope, path
      rescue
      end

      def method_missing(key, value = nil)
        store key.to_sym, value if value
      end

      def lines
        file_contents.lines.to_a
      end

      def file_contents
        File.read(file_path)
      rescue
        ""
      end

      def file_path
        File.expand_path(path)
      end

      def path
        @path ||= DEFAULT_PATHS.find { |path|
          File.exist?(File.expand_path(path))
        }
      end

      def scope
        @scope ||= binding
      end
    end
  end
end
