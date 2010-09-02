module Vagrant
  class Config
    # The base class for all configuration classes. This implements
    # basic things such as the environment instance variable which all
    # config classes need as well as a basic `to_json` implementation.
    class Base
      attr_accessor :env

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

      def to_json(*a)
        opts = a.first if a.first.is_a?(Hash)
        opts ||= {}
        result = {}
        result.merge!('json_class' => self.class.name) if opts[:loadable]
        result.merge(instance_variables_hash).to_json(*a)
      end

      def instance_variables_hash
        instance_variables.inject({}) do |acc, iv|
          acc[iv.to_s[1..-1]] = instance_variable_get(iv) unless iv.to_sym == :@env
          acc
        end
      end
    end
  end
end
