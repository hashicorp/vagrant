module Hobo
  module Util
    def error_and_exit(error)
      puts <<-error
=====================================================================
Hobo experienced an error!

#{error.chomp}
=====================================================================
error
      exit
    end

    def logger
      HOBO_LOGGER
    end
  end
end  

