module Hobo
  module Error
      def error_and_exit(error)
        puts <<-error
=====================================================================
Hobo experienced an error!

#{error.chomp}
=====================================================================
error
        exit
      end
  end
end
