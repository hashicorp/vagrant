# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)
require 'digest/md5'
require 'digest/sha1'

require 'vagrant/util/file_checksum'

describe FileChecksum do
  include_context "unit"

  let(:environment) { isolated_environment }

  it "should return a valid checksum for a file" do
    file = environment.workdir.join("file")
    file.open("w+") { |f| f.write("HELLO!") }

    # Check multiple digests
    instance = described_class.new(file, Digest::MD5)
    expect(instance.checksum).to eq("9ac96c64417b5976a58839eceaa77956")

    instance = described_class.new(file, Digest::SHA1)
    expect(instance.checksum).to eq("264b207c7913e461c43d0f63d2512f4017af4755")
  end

  it "should support initialize with class or string" do
    file = environment.workdir.join("file")
    file.open("w+") { |f| f.write("HELLO!") }

    %w(md5 sha1 sha256 sha384 sha512).each do |type|
      klass = Digest.const_get(type.upcase)
      t_i = described_class.new(file, type)
      k_i = described_class.new(file, klass)
      expect(t_i.checksum).to eq(k_i.checksum)
    end
  end

  context "with an invalid digest" do
    let(:fake_digest) { :fake_digest }

    it "should raise an exception if the box has an invalid checksum type" do
      file = environment.workdir.join("file")
      file.open("w+") { |f| f.write("HELLO!") }

      expect{ described_class.new(file, fake_digest) }.to raise_error(Vagrant::Errors::BoxChecksumInvalidType)
    end
  end
end
