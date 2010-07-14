module Vagrant
  module Util
    def self.included(base)
      base.extend(self)
    end

    def error_and_exit(key, data = {})
      abort <<-error
=====================================================================
Vagrant experienced an error!

#{Translator.t(key, data).chomp}
=====================================================================
error
    end

    def wrap_output
      puts "====================================================================="
      yield
      puts "====================================================================="
    end
  end
end
