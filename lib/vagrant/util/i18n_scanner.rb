require 'i18n/tasks/scanners/pattern_scanner'
module Vagrant
  module Util
    # Scan error_key, error_namespace, and I18n.t usages. Supports one error_namespace call per file.
    class I18nScanner < ::I18n::Tasks::Scanners::PatternScanner
      ERROR_KEY_RE            = /\berror_key[( ]\s*(#{LITERAL_RE})(?:\s*,\s*)?(#{LITERAL_RE})?/
      ERROR_NAMESPACE_RE      = /\berror_namespace[( ]\s*(#{LITERAL_RE})/
      ERROR_KEY_ARG_RE        = /[\s(,](?::error_key\s*=>\s*|error_key:\s*|:_key\s*=>\s*|_key:\s*)(#{LITERAL_RE})/
      DEFAULT_ERROR_NAMESPACE = 'vagrant.errors'

      def scan_file(path)
        # scan I18n.t calls
        keys = super

        # read file
        src  = nil
        File.open(path, 'rb') { |f| src = f.read }

        # scan error_key(key, namespace) calls
        src.scan ERROR_KEY_RE do |match|
          key, namespace = *match
          key            = "#{strip_literal(namespace || 'vagrant.errors') + '.'}#{strip_literal key}"
          keys << key if valid_key?(key)
        end

        # scan error_namespace and key as hash argument
        namespace = src.scan(ERROR_NAMESPACE_RE)[0]
        namespace = namespace ? strip_literal(namespace[0]) : DEFAULT_ERROR_NAMESPACE
        src.scan ERROR_KEY_ARG_RE do |match|
          key = "#{namespace}.#{strip_literal(match[0])}"
          keys << key if valid_key?(key)
        end

        keys
      end
    end
  end
end
