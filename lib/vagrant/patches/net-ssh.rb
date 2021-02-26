require "net/ssh"

# Only patch if we have version 6.1.0 loaded as
# these patches pull 6.1.0 up to the as of now
# current 6.2.0 beta
if Net::SSH::Version::STRING == "6.1.0"
  require "net/ssh/authentication/agent"
  # net/ssh/authentication/agent
  Net::SSH::Authentication::Agent.class_eval do
    SSH2_AGENT_LOCK = 22
    SSH2_AGENT_UNLOCK = 23

    # lock the ssh agent with password
    def lock(password)
      type, = send_and_wait(SSH2_AGENT_LOCK, :string, password)
      raise AgentError, "could not lock agent" if type != SSH_AGENT_SUCCESS
    end

    # unlock the ssh agent with password
    def unlock(password)
      type, = send_and_wait(SSH2_AGENT_UNLOCK, :string, password)
      raise AgentError, "could not unlock agent" if type != SSH_AGENT_SUCCESS
    end
  end

  require "net/ssh/authentication/certificate"
  # net/ssh/authentication/certificate
  Net::SSH::Authentication::Certificate.class_eval do
    def ssh_do_verify(sig, data, options = {})
      key.ssh_do_verify(sig, data, options)
    end
  end

  require "net/ssh/authentication/ed25519"
  # net/ssh/authentication/ed25519
  Net::SSH::Authentication::ED25519::PubKey.class_eval do
    def ssh_do_verify(sig, data, options = {})
      @verify_key.verify(sig,data)
    end
  end

  require "net/ssh/transport/algorithms"
  # net/ssh/transport/algorithms
  Net::SSH::Transport::Algorithms::DEFAULT_ALGORITHMS[:host_key].push("rsa-sha2-256").push("rsa-sha2-512")

  require "net/ssh/transport/cipher_factory"
  # net/ssh/transport/cipher_factory
  Net::SSH::Transport::CipherFactory::SSH_TO_OSSL["aes256-ctr"] = ::OpenSSL::Cipher.ciphers.include?("aes-256-ctr") ? "aes-256-ctr" : "aes-256-ecb"
  Net::SSH::Transport::CipherFactory::SSH_TO_OSSL["aes192-ctr"] = ::OpenSSL::Cipher.ciphers.include?("aes-192-ctr") ? "aes-192-ctr" : "aes-192-ecb"
  Net::SSH::Transport::CipherFactory::SSH_TO_OSSL["aes128-ctr"] = ::OpenSSL::Cipher.ciphers.include?("aes-128-ctr") ? "aes-128-ctr" : "aes-128-ecb"

  require "net/ssh/transport/kex/abstract"
  # net/ssh/transport/kex/abstract
  Net::SSH::Transport::Kex::Abstract.class_eval do
    def matching?(key_ssh_type, host_key_alg)
      return true if key_ssh_type == host_key_alg
      return true if key_ssh_type == 'ssh-rsa' && ['rsa-sha2-512', 'rsa-sha2-256'].include?(host_key_alg)
    end

    def verify_server_key(key) #:nodoc:
      unless matching?(key.ssh_type, algorithms.host_key)
        raise Net::SSH::Exception, "host key algorithm mismatch '#{key.ssh_type}' != '#{algorithms.host_key}'"
      end

      blob, fingerprint = generate_key_fingerprint(key)

      unless connection.host_key_verifier.verify(key: key, key_blob: blob, fingerprint: fingerprint, session: connection)
        raise Net::SSH::Exception, 'host key verification failed'
      end
    end

    def verify_signature(result) #:nodoc:
      response = build_signature_buffer(result)

      hash = digester.digest(response.to_s)

      server_key = result[:server_key]
      server_sig = result[:server_sig]
      unless connection.host_key_verifier.verify_signature { server_key.ssh_do_verify(server_sig, hash, host_key: algorithms.host_key) }
        raise Net::SSH::Exception, 'could not verify server signature'
      end

      hash
    end
  end

  require "net/ssh/transport/openssl"
  # net/ssh/transport/openssl
  OpenSSL::PKey::RSA.class_eval do
    def ssh_do_verify(sig, data, options = {})
      digester =
        if options[:host_key] == "rsa-sha2-512"
          OpenSSL::Digest::SHA512.new
        elsif options[:host_key] == "rsa-sha2-256"
          OpenSSL::Digest::SHA256.new
        else
          OpenSSL::Digest::SHA1.new
        end

      verify(digester, sig, data)
    end
  end

  OpenSSL::PKey::DSA.class_eval do
    def ssh_do_verify(sig, data, options = {})
      sig_r = sig[0,20].unpack("H*")[0].to_i(16)
      sig_s = sig[20,20].unpack("H*")[0].to_i(16)
      a1sig = OpenSSL::ASN1::Sequence([
        OpenSSL::ASN1::Integer(sig_r),
        OpenSSL::ASN1::Integer(sig_s)
      ])
      return verify(OpenSSL::Digest::SHA1.new, a1sig.to_der, data)
    end
  end

  OpenSSL::PKey::EC.class_eval do
    def ssh_do_verify(sig, data, options = {})
      digest = digester.digest(data)
      a1sig = nil

      begin
        sig_r_len = sig[0, 4].unpack('H*')[0].to_i(16)
        sig_l_len = sig[4 + sig_r_len, 4].unpack('H*')[0].to_i(16)

        sig_r = sig[4, sig_r_len].unpack('H*')[0]
        sig_s = sig[4 + sig_r_len + 4, sig_l_len].unpack('H*')[0]

        a1sig = OpenSSL::ASN1::Sequence([
          OpenSSL::ASN1::Integer(sig_r.to_i(16)),
          OpenSSL::ASN1::Integer(sig_s.to_i(16))
        ])
      rescue StandardError
      end

      if a1sig.nil?
        return false
      else
        dsa_verify_asn1(digest, a1sig.to_der)
      end
    end
  end
end
