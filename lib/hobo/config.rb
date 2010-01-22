module Hobo
  class Config
    @@config = nil
    class << self
      # TODO Config.config is awkward
      def config 
        @@config
      end
      
      def from_hash!(hash)
        @@config = hash_to_struct(hash)
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
