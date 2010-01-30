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

    key = keys.shift.to_sym
    if keys.empty? 
      raise InvalidSettingAlteration if cfg[key].instance_of?(Hash)
      return cfg[key] = val if keys.empty?
    end

    set_config_value(keys.join('.'), val, cfg[key])    
  end

  class InvalidSettingAlteration < StandardError; end
end
