require "net/ssh/version"

# Only patch if we have version 6.1.0 loaded as
# these patches pull 6.1.0 up to the as of now
# current 6.2.0 beta
if Net::SSH::Version::STRING == "6.1.0"
  module DeprecatedRsaSha1
    module KeyManager
      def initialize(logger, options={})
        @deprecated_rsa_sha1 = options.delete(:deprecated_rsa_sha1)
        super
      end

      def sign(identity, data)
        info = known_identities[identity] or raise Net::SSH::Authentication::KeyManager::KeyManagerError, "the given identity is unknown to the key manager"

        if info[:key].nil? && info[:from] == :file
          begin
            info[:key] = Net::SSH::KeyFactory.load_private_key(info[:file], options[:passphrase], !options[:non_interactive], options[:password_prompt])
            if @deprecated_rsa_sha1 && info[:key].respond_to?(:deprecated_rsa_sha1=)
              info[:key].deprecated_rsa_sha1 = true
              Vagrant.global_logger.debug("set RSA SHA1 deprecation on private key: #{info[:key].fingerprint}")
            end
          rescue OpenSSL::OpenSSLError, Exception => e
            raise Net::SSH::Authentication::KeyManager::KeyManagerError, "the given identity is known, but the private key could not be loaded: #{e.class} (#{e.message})"
          end
        end

        if info[:key]
          return Net::SSH::Buffer.from(:string, identity.ssh_signature_type,
            :mstring, info[:key].ssh_do_sign(data.to_s)).to_s
        end

        if info[:from] == :agent
          raise Net::SSH::Authentication::KeyManager::KeyManagerError, "the agent is no longer available" unless agent
          return agent.sign(info[:identity], data.to_s)
        end

        raise Net::SSH::Authentication::KeyManager::KeyManagerError, "[BUG] can't determine identity origin (#{info.inspect})"
      end

      def load_identities(identities, ask_passphrase, ignore_decryption_errors)
        identities.map do |identity|
          begin
            case identity[:load_from]
            when :pubkey_file
              key = Net::SSH::KeyFactory.load_public_key(identity[:pubkey_file])
              if @deprecated_rsa_sha1 && key.respond_to?(:deprecated_rsa_sha1=)
                key.deprecated_rsa_sha1 = true
                Vagrant.global_logger.debug("set RSA SHA1 deprecation on public key: #{key.fingerprint}")
              end
              { public_key: key, from: :file, file: identity[:privkey_file] }
            when :privkey_file
              private_key = Net::SSH::KeyFactory.load_private_key(
                identity[:privkey_file], options[:passphrase], ask_passphrase, options[:password_prompt]
              )
              key = private_key.send(:public_key)
              if @deprecated_rsa_sha1 && key.respond_to?(:deprecated_rsa_sha1=)
                key.deprecated_rsa_sha1 = true
                private_key.deprecated_rsa_sha1 = true
                Vagrant.global_logger.debug("set RSA SHA1 deprecation on public key: #{key.fingerprint}")
                Vagrant.global_logger.debug("set RSA SHA1 deprecation on private key: #{private_key.fingerprint}")
              end
              { public_key: key, from: :file, file: identity[:privkey_file], key: private_key }
            when :data
              private_key = Net::SSH::KeyFactory.load_data_private_key(
                identity[:data], options[:passphrase], ask_passphrase, "<key in memory>", options[:password_prompt]
              )
              key = private_key.send(:public_key)
              if @deprecated_rsa_sha1 && key.respond_to?(:deprecated_rsa_sha1=)
                key.deprecated_rsa_sha1 = true
                private_key.deprecated_rsa_sha1 = true
                Vagrant.global_logger.debug("set RSA SHA1 deprecation on public key: #{key.fingerprint}")
                Vagrant.global_logger.debug("set RSA SHA1 deprecation on private key: #{private_key.fingerprint}")
              end
              { public_key: key, from: :key_data, data: identity[:data], key: private_key }
            else
              identity
            end
          rescue OpenSSL::PKey::RSAError, OpenSSL::PKey::DSAError, OpenSSL::PKey::ECError, OpenSSL::PKey::PKeyError, ArgumentError => e
            if ignore_decryption_errors
              identity
            else
              process_identity_loading_error(identity, e)
              nil
            end
          rescue Exception => e
            process_identity_loading_error(identity, e)
            nil
          end
        end.compact
      end
    end

    module AuthenticationSession
      def initialize(transport, options={})
        s_ver_str = transport.server_version.version.
          match(/OpenSSH_.*?(?<version>\d+\.\d+)/)&.[](:version).to_s
        Vagrant.global_logger.debug("ssh server version detected: #{s_ver_str}")
        if !s_ver_str.empty?
          begin
            ver = Gem::Version.new(s_ver_str)
            if ver >= Gem::Version.new("7.2")
              Vagrant.global_logger.debug("ssh server supports deprecation of RSA SHA1, deprecating")
              options[:deprecated_rsa_sha1] = true
            else
              Vagrant.global_logger.debug("ssh server does not support deprecation of RSA SHA1")
            end
          rescue ArgumentError => err
            Vagrant.global_logger.debug("failed to determine valid ssh server version - #{err}")
          end
        end
        super
      end
    end
  end

  require "net/ssh/transport/algorithms"
  # net/ssh/transport/algorithms
  [:kex, :host_key].each do |key|
    idx = Net::SSH::Transport::Algorithms::ALGORITHMS[key].index(
      Net::SSH::Transport::Algorithms::DEFAULT_ALGORITHMS[key].last
    )
    Net::SSH::Transport::Algorithms::DEFAULT_ALGORITHMS[key].push("rsa-sha2-512")
    Net::SSH::Transport::Algorithms::DEFAULT_ALGORITHMS[key].push("rsa-sha2-256")
    Net::SSH::Transport::Algorithms::ALGORITHMS[key].insert(idx, "rsa-sha2-256")
    Net::SSH::Transport::Algorithms::ALGORITHMS[key].insert(idx, "rsa-sha2-512")
  end

  require "net/ssh/authentication/key_manager"
  Net::SSH::Authentication::KeyManager.prepend(DeprecatedRsaSha1::KeyManager)
  require "net/ssh/authentication/session"
  Net::SSH::Authentication::Session.prepend(DeprecatedRsaSha1::AuthenticationSession)

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
    attr_accessor :deprecated_rsa_sha1

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

    def ssh_type
      deprecated_rsa_sha1 ? signature_algorithm : "ssh-rsa"
    end

    def signature_algorithm
      "rsa-sha2-256"
    end

    def ssh_do_sign(data)
      if deprecated_rsa_sha1
        sign(OpenSSL::Digest::SHA256.new, data)
      else
        sign(OpenSSL::Digest::SHA1.new, data)
      end
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

require "net/ssh"
