require "base64"
require "openssl"

require "vagrant/util/retryable"

module Vagrant
  module Util
    class Keypair
      extend Retryable

      # Creates an SSH keypair and returns it.
      #
      # @param [String] password Password for the key, or nil for no password.
      # @return [Array<String, String, String>] PEM-encoded public and private key,
      #   respectively. The final element is the OpenSSH encoded public
      #   key.
      def self.create(password=nil)
        # This sometimes fails with RSAError. It is inconsistent and strangely
        # sleeps seem to fix it. We just retry this a few times. See GH-5056
        rsa_key = nil
        retryable(on: OpenSSL::PKey::RSAError, sleep: 2, tries: 5) do
          rsa_key = OpenSSL::PKey::RSA.new(2048)
        end

        public_key  = rsa_key.public_key
        private_key = rsa_key.to_pem

        if password
          cipher      = OpenSSL::Cipher::Cipher.new('des3')
          private_key = rsa_key.to_pem(cipher, password)
        end

        # Generate the binary necessary for the OpenSSH public key.
        binary = [7].pack("N")
        binary += "ssh-rsa"
        ["e", "n"].each do |m|
          val  = public_key.send(m)
          data = val.to_s(2)

          first_byte = data[0,1].unpack("c").first
          if val < 0
            data[0] = [0x80 & first_byte].pack("c")
          elsif first_byte < 0
            data = 0.chr + data
          end

          binary += [data.length].pack("N") + data
        end

        openssh_key = "ssh-rsa #{Base64.encode64(binary).gsub("\n", "")} vagrant"
        public_key  = public_key.to_pem
        return [public_key, private_key, openssh_key]
      end
    end
  end
end
