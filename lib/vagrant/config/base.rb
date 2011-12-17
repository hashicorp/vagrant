module Vagrant
  module Config
    # The base class for all configuration classes. This implements
    # basic things such as the environment instance variable which all
    # config classes need as well as a basic `to_json` implementation.
    class Base
      # Loads configuration values from JSON back into the proper
      # configuration classes. By default, this is done by simply
      # iterating over all values in the JSON hash and assigning them
      # to instance variables on the class.
      def self.json_create(data)
        data.inject(new) do |result, data|
          key, value = data
          result.instance_variable_set("@#{key}".to_sym, value) if key != "json_class"
          result
        end
      end

      # Allows setting options from a hash. By default this simply calls
      # the `#{key}=` method on the config class with the value, which is
      # the expected behavior most of the time.
      def set_options(options)
        options.each do |key, value|
          send("#{key}=", value)
        end
      end

      # Called by {Top} after the configuration is loaded to validate
      # the configuaration objects. Subclasses should implement this
      # method and add any errors to the `errors` object given.
      #
      # @param [ErrorRecorder] errors
      def validate(env, errors); end

      # Converts the configuration to a raw hash by calling `#to_hash`
      # on all instance variables (if it can) and putting them into
      # a hash.
      def to_hash
        instance_variables_hash.inject({}) do |acc, data|
          k,v = data
          v = v.to_hash if v.respond_to?(:to_hash)
          acc[k] = v
          acc
        end
      end

      # Converts to JSON, with the `json_class` field set so that when
      # the JSON is parsed back, it can be loaded back into the proper class.
      # See {json_create}.
      def to_json(*a)
        instance_variables_hash.to_json(*a)
      end

      # Returns the instance variables as a hash of key-value pairs.
      def instance_variables_hash
        instance_variables.inject({}) do |acc, iv|
          acc[iv.to_s[1..-1]] = instance_variable_get(iv) unless iv.to_sym == :@top
          acc
        end
      end
    end
  end
end
