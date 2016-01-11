require "fiddle/import"

module Vagrant
  module Util
    module WindowsPath
      module API
        extend Fiddle::Importer
        dlload 'kernel32.dll'
        extern("int GetLongPathNameA(char*, char*, int)", :stdcall)
      end

      # Converts a Windows shortname to a long name. This only works
      # for ASCII paths currently and doesn't use the wide character
      # support.
      def self.longname(name)
        # We loop over the API call in case we didn't allocate enough
        # buffer space. In general it is usually enough.
        bufferlen = 250
        buffer    = nil
        while true
          buffer = ' ' * bufferlen
          len    = API.GetLongPathNameA(name.to_s, buffer, buffer.size)
          if bufferlen < len
            # If the length returned is larger than our buffer length,
            # it is the API telling us it needs more space. Allocate it
            # and retry.
            bufferlen = len
            continue
          end

          break
        end

        return buffer.rstrip.chomp("\0")
      end
    end
  end
end
