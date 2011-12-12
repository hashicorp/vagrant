module Vagrant
  module Util
    class FileMode
      # This returns the file permissions as a string from
      # an octal number.
      def self.from_octal(octal)
        perms = sprintf("%o", octal)
        perms.reverse[0..2].reverse
      end
    end
  end
end
