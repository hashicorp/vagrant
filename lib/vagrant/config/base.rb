module Vagrant
  class Config
    # The base class for all configuration classes. This implements
    # basic things such as the environment instance variable which all
    # config classes need as well as a basic `to_json` implementation.
    class Base
      attr_accessor :env

      def [](key)
        send(key)
      end

      def to_json(*a)
        { 'json_class' => self.class.name }.merge(instance_variables_hash).to_json(*a)
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
