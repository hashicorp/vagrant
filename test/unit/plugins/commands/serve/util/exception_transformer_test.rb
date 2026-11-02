# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/serve/command")

describe VagrantPlugins::CommandServe::Util::ExceptionTransformer do
  include_context "unit"

  it "converts VagrantErrors into GRPC::BadStatus errors with a LocalizedMessage" do
    klass = Class.new
    vagrant_error = Class.new(Vagrant::Errors::VagrantError) do
      error_key("test_key")
    end
    klass.define_method(:wrapme) do |*args|
      raise vagrant_error.new
    end
    subklass = Class.new(klass)
    subklass.include described_class
    expect {
      subklass.new.wrapme
    }.to raise_error(an_instance_of(GRPC::BadStatus).and satisfy { |err|
      err.metadata["grpc-status-details-bin"] =~ /LocalizedMessage/
    })
  end

  it "converts non-VagrantErrors into GRPC::BadStatus errors without a LocalizedMessage" do
    klass = Class.new
    klass.define_method(:wrapme) do
      raise "just a regular error"
    end
    subklass = Class.new(klass)
    subklass.include described_class
    expect {
      subklass.new.wrapme
    }.to raise_error(an_instance_of(GRPC::BadStatus).and satisfy { |err|
      err.metadata["grpc-status-details-bin"].nil?
    })
  end
end
