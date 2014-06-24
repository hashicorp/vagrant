# This is an "interface" that should be implemented by any digest class
# passed into FileChecksum. Note that this isn't strictly enforced at
# the moment, and this class isn't directly used. It is merely here for
# documentation of structure of the class.
class DigestClass
  def update(string); end
  def hexdigest; end
end

class FileChecksum
  BUFFER_SIZE = 1024 * 8

  # Initializes an object to calculate the checksum of a file. The given
  # ``digest_klass`` should implement the ``DigestClass`` interface. Note
  # that the built-in Ruby digest classes duck type this properly:
  # Digest::MD5, Digest::SHA1, etc.
  def initialize(path, digest_klass)
    @digest_klass = digest_klass
    @path         = path
  end

  # This calculates the checksum of the file and returns it as a
  # string.
  #
  # @return [String]
  def checksum
    digest = @digest_klass.new
    buf = ''

    File.open(@path, "rb") do |f|
      while !f.eof
        begin
          f.readpartial(BUFFER_SIZE, buf)
          digest.update(buf)
        rescue EOFError
          # Although we check for EOF earlier, this seems to happen
          # sometimes anyways [GH-2716].
          break
        end
      end
    end

    return digest.hexdigest
  end
end
