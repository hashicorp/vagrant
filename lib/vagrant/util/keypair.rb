require "base64"
require "ed25519"
require "securerandom"

require "vagrant/util/retryable"

module Vagrant
  module Util
    class Keypair
      class Ed25519
        # Magic string header
        AUTH_MAGIC = "openssh-key-v1".freeze
        # Key type identifier
        KEY_TYPE = "ssh-ed25519".freeze
        # Header of private key file content
        PRIVATE_KEY_START = "-----BEGIN OPENSSH PRIVATE KEY-----\n".freeze
        # Footer of private key file content
        PRIVATE_KEY_END = "-----END OPENSSH PRIVATE KEY-----".freeze

        # Encodes given string
        #
        # @param [String] s String to encode
        # @return [String]
        def self.string(s)
          [s.length].pack("N") + s
        end

        # Encodes given string with padding to block size
        #
        # @param [String] s String to encode
        # @param [Integer] blocksize Defined block size
        # @return [String]
        def self.padded_string(s, blocksize)
          pad = blocksize - (s.length % blocksize)
          string(s + Array(1..pad).pack("c*"))
        end

        # Creates an ed25519 SSH key pair
        # @return [Array<String, String, String>] Public key, openssh private key, openssh public key with comment
        # @note Password support was not included as it's not actively used anywhere. If it ends up being
        # something that's needed, it can be revisited
        def self.create(password=nil)
          if password
            raise NotImplementedError,
                  "Ed25519 key pair generation does not support passwords"
          end

          # Generate the key
          base_key = ::Ed25519::SigningKey.generate
          # Define the comment used for the key
          comment = "vagrant"

          # Grab the raw public key
          public_key = base_key.verify_key.to_bytes
          # Encode the public key for use building the openssh private key
          encoded_public_key = string(KEY_TYPE) + string(public_key)
          # Format the public key into the openssh public key format for writing
          openssh_public_key = "#{KEY_TYPE} #{Base64.encode64(encoded_public_key).gsub("\n", "")} #{comment}"

          # Agent encoded private key is used when building the openssh private key
          # (https://datatracker.ietf.org/doc/html/draft-miller-ssh-agent#section-4.2.3)
          # (https://dnaeon.github.io/openssh-private-key-binary-format/)
          agent_private_key = [
            ([SecureRandom.random_number((2**32)-1)] * 2).pack("NN"), # checkint, random uint32 value, twice (used for encryption verification)
            encoded_public_key, # includes the key type and public key
            string(base_key.seed + public_key), # private key with public key concatenated
            string(comment), # comment for the key
          ].join

          # Build openssh private key data (https://github.com/openssh/openssh-portable/blob/master/PROTOCOL.key)
          private_key = [
            AUTH_MAGIC + "\0", # Magic string
            string("none"), # cipher name, no encryption, so none
            string("none"), # kdf name, no encryption, so none
            string(""), # kdf options/data, no encryption, so empty string
            [1].pack("N"), # Number of keys (just one)
            string(encoded_public_key), # The public key
            padded_string(agent_private_key, 8) # Private key encoded with agent rules, padded for 8 byte block size
          ].join

          # Create the openssh private key content
          openssh_private_key = [
            PRIVATE_KEY_START,
            Base64.encode64(private_key),
            PRIVATE_KEY_END,
          ].join

          return [public_key, openssh_private_key, openssh_public_key]
        end
      end

      class Rsa
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
            cipher      = OpenSSL::Cipher.new('des3')
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

      # Supported key types.
      VALID_TYPES = {ed25519: Ed25519, rsa: Rsa}.freeze
      # Ordered mapping of openssh key type name to lookup name
      PREFER_KEY_TYPES = {"ssh-ed25519".freeze => :ed25519, "ssh-rsa".freeze => :rsa}.freeze

      def self.create(password=nil, type: :rsa)
        if !VALID_TYPES.key?(type)
          raise ArgumentError,
                "Invalid key type requested (supported types: #{VALID_TYPES.keys.map(&:inspect)})"
        end

        VALID_TYPES[type].create(password)
      end
    end
  end
end
