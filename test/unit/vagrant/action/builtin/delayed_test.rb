# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Delayed do
  let(:app) { lambda {|*_|} }
  let(:env) { {} }

  it "should raise error when callable does not provide #call" do
    expect { described_class.new(app, env, true) }.
      to raise_error(TypeError)
  end

  it "should delay executing action to end of stack" do
    result = []
    one = proc{ |*_| result << :one }
    two = proc{ |*_| result << :two }
    builder = Vagrant::Action::Builder.build(described_class, two)
    builder.use(one)
    builder.call(env)
    expect(result.first).to eq(:one)
    expect(result.last).to eq(:two)
  end
end
