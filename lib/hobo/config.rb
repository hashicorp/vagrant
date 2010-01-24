module Hobo
  
  
  module_function

  def config
    @@config
  end

  def alterable_config
    @@alterable_config
  end

  def config!(hash)
    @@alterable_config = hash.dup
    @@config = hash.freeze
  end

  def set_config_value(chain, val, cfg=@@alterable_config)
    keys = chain.split('.')
    key = keys.shift.to_sym
    if keys.empty? 
      raise InvalidSettingAlteration if cfg[key].instance_of?(Hash)
      return cfg[key] = val if keys.empty?
    end

    set_config_value(keys.join('.'), val, cfg[key])    
  end

  class InvalidSettingAlteration < StandardError; end
end
