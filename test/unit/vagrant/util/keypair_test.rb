# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require "openssl"
require "ed25519"
require "net/ssh"

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/keypair"

describe Vagrant::Util::Keypair do
  describe Vagrant::Util::Keypair::Rsa do
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

  describe Vagrant::Util::Keypair::Ed25519 do
    describe ".create" do
      it "generates a usable keypair with no password" do
        pubkey, ossh_privkey, _ = described_class.create


        privkey = Net::SSH::Authentication::ED25519::PrivKey.read(ossh_privkey, "").sign_key
        pubkey = Ed25519::VerifyKey.new(pubkey)

        message = "vagrant test"
        signature = privkey.sign(message)
        expect(pubkey.verify(signature, message)).to be_truthy
      end

      it "does not generate a keypair that requires a password" do
        expect {
          described_class.create("my password")
        }.to raise_error(NotImplementedError)
      end
    end
  end
end
