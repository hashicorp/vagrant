module Vagrant
  module Util
    def error_and_exit(key, data = {})
      abort <<-error
=====================================================================
Vagrant experienced an error!

#{Translator.t(key, data).chomp}
=====================================================================
error
    end
  end
end
