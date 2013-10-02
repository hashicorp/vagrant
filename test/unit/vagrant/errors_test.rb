require File.expand_path("../../base", __FILE__)

describe Vagrant::Errors::VagrantError do
  describe "subclass with error key" do
    let(:klass) do
      Class.new(described_class) do
        error_key("test_key")
      end
    end

    subject { klass.new }

    it "should use the translation for the message" do
      subject.to_s.should == "test value"
    end

    its("status_code") { should eq(1) }
  end

  describe "subclass with error message" do
    let(:klass) do
      Class.new(described_class) do
        error_message("foo")
      end
    end

    subject { klass.new }

    it "should use the translation for the message" do
      subject.to_s.should == "foo"
    end
  end
end
