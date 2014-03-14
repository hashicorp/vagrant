require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V1::DummyConfig do
  it "should allow attribute setting" do
    expect { subject.foo = :bar }.
      to_not raise_error
  end

  it "should allow method calls that return more DummyConfigs" do
    expect(subject.foo).to be_kind_of(described_class)
  end

  it "should allow hash access" do
    expect { subject[:foo] }.
      to_not raise_error

    expect(subject[:foo]).to be_kind_of(described_class)
  end

  it "should allow setting hash values" do
    expect { subject[:foo] = :bar }.
      to_not raise_error
  end
end
