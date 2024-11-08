# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "net/ssh"
Vagrant.require "net/ssh/buffer"

# Set the version requirement for when net-ssh should be patched
NET_SSH_PATCH_REQUIREMENT = Gem::Requirement.new(">= 7.0.0", "<= 7.3")

# This patch provides support for properly loading ECDSA private keys
if NET_SSH_PATCH_REQUIREMENT.satisfied_by?(Gem::Version.new(Net::SSH::Version::STRING))
  Net::SSH::Buffer.class_eval do
    def vagrant_read_private_keyblob(type)
      case type
      when /^ecdsa\-sha2\-(\w*)$/
        curve_name_in_type = $1
        curve_name_in_key = read_string

        unless curve_name_in_type == curve_name_in_key
          raise Net::SSH::Exception, "curve name mismatched (`#{curve_name_in_key}' with `#{curve_name_in_type}')"
        end

        public_key_oct = read_string
        priv_key_bignum = read_bignum
        begin
          curvename = OpenSSL::PKey::EC::CurveNameAlias[curve_name_in_key]
          group = OpenSSL::PKey::EC::Group.new(curvename)
          point = OpenSSL::PKey::EC::Point.new(group, OpenSSL::BN.new(public_key_oct, 2))
          priv_bn = OpenSSL::BN.new(priv_key_bignum, 2)
          asn1 = OpenSSL::ASN1::Sequence(
            [
              OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(0)),
              OpenSSL::ASN1::Sequence.new(
                [
                  OpenSSL::ASN1::ObjectId("id-ecPublicKey"),
                  OpenSSL::ASN1::ObjectId(curvename)
                ]
              ),
              OpenSSL::ASN1::OctetString.new(
                OpenSSL::ASN1::Sequence.new(
                  [
                    OpenSSL::ASN1::Integer.new(OpenSSL::BN.new(1)),
                    OpenSSL::ASN1::OctetString.new(priv_bn.to_s(2)),
                    OpenSSL::ASN1::ASN1Data.new(
                      [
                        OpenSSL::ASN1::BitString.new(point.to_octet_string(:uncompressed)),
                      ], 1, :CONTEXT_SPECIFIC,
                    )
                  ]
                ).to_der
              )
            ]
          )

          key = OpenSSL::PKey::EC.new(asn1.to_der)

          return key
        rescue OpenSSL::PKey::ECError
          raise NotImplementedError, "unsupported key type `#{type}'"
        end
      else
        netssh_read_private_keyblob(type)
      end
    end

    alias_method :netssh_read_private_keyblob, :read_private_keyblob
    alias_method :read_private_keyblob, :vagrant_read_private_keyblob
  end

  OpenSSL::PKey::EC::Point.class_eval do
    include Net::SSH::Authentication::PubKeyFingerprint
    def to_pem
      "#{ssh_type} #{self.to_bn.to_s(2)}"
    end
  end
end
