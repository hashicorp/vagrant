module Hobo
  module_function
  
  def config
    @@config
  end

  def config!(hash)
    @@config = hash
  end

  def set_config_value(chain, val, cfg=@@config)
    keys = chain.split('.')

    return if keys.empty?

    if keys.length == 1
      # If we're out of keys and the value for this key is not a leaf blow up
      raise InvalidSettingAlteration if cfg[keys.first.to_sym].is_a?(Hash)
      
      # set the value and return if the value is a leaf
      return cfg[keys.first.to_sym] = val
    end

    set_config_value(keys[1..-1].join('.'), val, cfg[keys.first.to_sym])    
  end

  class InvalidSettingAlteration < StandardError; end
end
