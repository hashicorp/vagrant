# This is an "interface" that should be implemented by any digest class
# passed into FileChecksum. Note that this isn't strictly enforced at
# the moment, and this class isn't directly used. It is merely here for
# documentation of structure of the class.

require "vagrant/errors"

class DigestClass
  def update(string); end
  def hexdigest; end
end

class FileChecksum
  BUFFER_SIZE = 1024 * 8

  # Supported file checksum
  CHECKSUM_MAP = {
    :md5 => Digest::MD5,
    :sha1 => Digest::SHA1,
    :sha256 => Digest::SHA256,
    :sha384 => Digest::SHA384,
    :sha512 => Digest::SHA512
  }.freeze

  # Initializes an object to calculate the checksum of a file. The given
  # ``digest_klass`` should implement the ``DigestClass`` interface. Note
  # that the built-in Ruby digest classes duck type this properly:
  # Digest::MD5, Digest::SHA1, etc.
  def initialize(path, digest_klass)
    if digest_klass.is_a?(Class)
      @digest_klass = digest_klass
    else
      @digest_klass = load_digest(digest_klass)
    end

    @path = path
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

    digest.hexdigest
  end

  private

  def load_digest(type)
    digest = CHECKSUM_MAP[type.to_s.to_sym]
    if digest.nil?
      raise Vagrant::Errors::BoxChecksumInvalidType,
        type: type.to_s,
        types: CHECKSUM_MAP.keys.join(', ')
    end
    digest
  end
end
