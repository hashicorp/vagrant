module Hobo
  class Config
    @@settings = nil
    class << self
      
      def settings
        @@settings
      end
      
      def from_hash!(hash)
        @@settings = hash_to_struct(hash)
      end

      private

      def hash_to_struct(value)
        return value unless value.instance_of?(Hash)

        result = value.inject({}) do |acc, pair|
          acc[pair.first] = hash_to_struct(pair.last)
          acc
        end
        
        OpenStruct.new(result)
      end
    end
  end
end
