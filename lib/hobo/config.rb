module Hobo
  module_function

  def config
    @@config
  end

  def alterable_config
    @@alterable_config
  end

  def set_config!(hash)
    @@alterable_config = hash.dup
    @@config = hash.freeze
  end
end
