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

      described_class.new(data).keys.should == ["foo", "bar"]
    end
  end

  describe "#delete" do
    it "should delete nothing if the key doesn't exist" do
      data = "foo"

      instance = described_class.new(data)
      instance.delete("key")
      instance.value.should == data
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
      instance.value.should == new_data
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
      subject.get("bar").should == "content"
    end

    it "should get nil for nonexistent values" do
      subject.get("baz").should be_nil
    end

    it "should get complicated keys" do
      result = subject.get("/Users/studio/Projects (studio)/tubes/.vagrant/machines/web/vmware_fusion/vm.vmwarevm")
      result.should == "complex"
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
      instance.value.should == new_data
    end
  end
end
