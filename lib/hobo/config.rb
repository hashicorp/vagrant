module Hobo

  module_function

  def config
    @@config
  end

  def config_from_hash!(hash)
    @@config = Config.from_hash(hash)
  end

  class Config
    class << self
      def from_hash(value)
        return value unless value.instance_of?(Hash)

        result = value.inject({}) do |acc, pair|
          acc[pair.first] = from_hash(pair.last)
          acc
        end
        
        OpenStruct.new(result)
      end
    end
  end
end
