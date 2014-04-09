require File.expand_path("../../../base", __FILE__)

require "vagrant/util/string_block_editor"

describe Vagrant::Util::StringBlockEditor do
  describe "#keys" do
    it "should return all the keys" do
      data = <<DATA
# VAGRANT-BEGIN: foo
value
# VAGRANT-END: foo
another
# VAGRANT-BEGIN: bar
content
# VAGRANT-END: bar
DATA

      expect(described_class.new(data).keys).to eq(["foo", "bar"])
    end
  end

  describe "#delete" do
    it "should delete nothing if the key doesn't exist" do
      data = "foo"

      instance = described_class.new(data)
      instance.delete("key")
      expect(instance.value).to eq(data)
    end

    it "should delete the matching blocks if they exist" do
      data = <<DATA
# VAGRANT-BEGIN: foo
value
# VAGRANT-END: foo
# VAGRANT-BEGIN: foo
another
# VAGRANT-END: foo
another
# VAGRANT-BEGIN: bar
content
# VAGRANT-END: bar
DATA

      new_data = <<DATA
another
# VAGRANT-BEGIN: bar
content
# VAGRANT-END: bar
DATA

      instance = described_class.new(data)
      instance.delete("foo")
      expect(instance.value).to eq(new_data)
    end
  end

  describe "#get" do
    let(:data) do
      <<DATA
# VAGRANT-BEGIN: bar
content
# VAGRANT-END: bar
# VAGRANT-BEGIN: /Users/studio/Projects (studio)/tubes/.vagrant/machines/web/vmware_fusion/vm.vmwarevm
complex
# VAGRANT-END: /Users/studio/Projects (studio)/tubes/.vagrant/machines/web/vmware_fusion/vm.vmwarevm
DATA
    end

    subject { described_class.new(data) }

    it "should get the value" do
      expect(subject.get("bar")).to eq("content")
    end

    it "should get nil for nonexistent values" do
      expect(subject.get("baz")).to be_nil
    end

    it "should get complicated keys" do
      result = subject.get("/Users/studio/Projects (studio)/tubes/.vagrant/machines/web/vmware_fusion/vm.vmwarevm")
      expect(result).to eq("complex")
    end
  end

  describe "#insert" do
    it "should insert the given key and value" do
      data = <<DATA
# VAGRANT-BEGIN: bar
content
# VAGRANT-END: bar
DATA

      new_data = <<DATA
#{data.chomp}
# VAGRANT-BEGIN: foo
value
# VAGRANT-END: foo
DATA

      instance = described_class.new(data)
      instance.insert("foo", "value")
      expect(instance.value).to eq(new_data)
    end
  end
end
