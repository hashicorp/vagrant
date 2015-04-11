require "openssl"

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/keypair"

describe Vagrant::Util::Keypair do
  describe ".create" do
    it "generates a usable keypair with no password" do
      # I don't know how to validate the final return value yet...
      pubkey, privkey, _ = described_class.create

      pubkey  = OpenSSL::PKey::RSA.new(pubkey)
      privkey = OpenSSL::PKey::RSA.new(privkey)

      encrypted = pubkey.public_encrypt("foo")
      decrypted = privkey.private_decrypt(encrypted)

      expect(decrypted).to eq("foo")
    end

    it "generates a keypair that requires a password" do
      pubkey, privkey, _ = described_class.create("password")

      pubkey  = OpenSSL::PKey::RSA.new(pubkey)
      privkey = OpenSSL::PKey::RSA.new(privkey, "password")

      encrypted = pubkey.public_encrypt("foo")
      decrypted = privkey.private_decrypt(encrypted)

      expect(decrypted).to eq("foo")
    end
  end
end
