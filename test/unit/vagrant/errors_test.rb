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
      expect(subject.to_s).to eq("test value")
    end

    describe '#status_code' do
      subject { super().status_code }
      it { should eq(1) }
    end
  end

  describe "passing error key through options" do
    subject { described_class.new(_key: "test_key") }

    it "should use the translation for the message" do
      expect(subject.to_s).to eq("test value")
    end
  end

  describe "subclass with error message" do
    let(:klass) do
      Class.new(described_class) do
        error_message("foo")
      end
    end

    subject { klass.new(data: "yep") }

    it "should use the translation for the message" do
      expect(subject.to_s).to eq("foo")
    end

    it "should expose translation keys to the user" do
      expect(subject.extra_data.length).to eql(1)
      expect(subject.extra_data).to have_key(:data)
      expect(subject.extra_data[:data]).to eql("yep")
    end

    it "should use a symbol initializer as a key" do
      subject = klass.new(:test_key)
      expect(subject.extra_data).to be_empty
      expect(subject.to_s).to eql("test value")
    end
  end
end
