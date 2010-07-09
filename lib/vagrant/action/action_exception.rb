module Vagrant
  class Action
    class ActionException < Exception
      attr_reader :key
      attr_reader :data

      def initialize(key, data = {})
        @key = key
        @data = data

        message = Vagrant::Util::Translator.t(key, data)
        super(message)
      end
    end
  end
end
