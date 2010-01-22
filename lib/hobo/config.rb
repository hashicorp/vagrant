module Hobo
  class Config
    @@config = nil
    class << self
      def config 
        @@config
      end
      
      def parse!(source)
        @@config ||= parse_to_struct(source)
      end

      private

      def parse_to_struct(value)
        return value unless value.instance_of?(Hash)

        result = value.inject({}) do |acc, pair|
          acc[pair.first] = parse_to_struct(pair.last)
          acc
        end
        
        OpenStruct.new(result)
      end
    end
  end
end
