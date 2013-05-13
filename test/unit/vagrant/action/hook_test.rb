require File.expand_path("../../../base", __FILE__)

require "vagrant/action/builder"
require "vagrant/action/hook"

describe Vagrant::Action::Hook do
  describe "defaults" do
    its("after_hooks")   { should be_empty }
    its("before_hooks")  { should be_empty }
    its("append_hooks")  { should be_empty }
    its("prepend_hooks") { should be_empty }
  end

  describe "before hooks" do
    let(:existing) { "foo" }

    it "should append them" do
      block = Proc.new {}

      subject.before(existing, 1)
      subject.before(existing, 2)
      subject.before(existing, 3, :arg, &block)

      subject.before_hooks[existing].should == [
        [1, [], nil],
        [2, [], nil],
        [3, [:arg], block]
      ]
    end
  end

  describe "after hooks" do
    let(:existing) { "foo" }

    it "should append them" do
      block = Proc.new {}

      subject.after(existing, 1)
      subject.after(existing, 2)
      subject.after(existing, 3, :arg, &block)

      subject.after_hooks[existing].should == [
        [1, [], nil],
        [2, [], nil],
        [3, [:arg], block]
      ]
    end
  end

  describe "append" do
    it "should make a list" do
      block = Proc.new {}

      subject.append(1)
      subject.append(2)
      subject.append(3, :arg, &block)

      subject.append_hooks.should == [
        [1, [], nil],
        [2, [], nil],
        [3, [:arg], block]
      ]
    end
  end

  describe "prepend" do
    it "should make a list" do
      block = Proc.new {}

      subject.prepend(1)
      subject.prepend(2)
      subject.prepend(3, :arg, &block)

      subject.prepend_hooks.should == [
        [1, [], nil],
        [2, [], nil],
        [3, [:arg], block]
      ]
    end
  end

  describe "applying" do
    let(:builder) { Vagrant::Action::Builder.new }

    it "should build the proper stack" do
      subject.prepend("1", 2)
      subject.append("9")
      subject.after("1", "2")
      subject.before("9", "8")

      subject.apply(builder)

      builder.stack.should == [
        ["1", [2], nil],
        ["2", [], nil],
        ["8", [], nil],
        ["9", [], nil]
      ]
    end

    it "should not prepend or append if disabled" do
      builder.use("3")
      builder.use("8")

      subject.prepend("1", 2)
      subject.append("9")
      subject.after("3", "4")
      subject.before("8", "7")

      subject.apply(builder, no_prepend_or_append: true)

      builder.stack.should == [
        ["3", [], nil],
        ["4", [], nil],
        ["7", [], nil],
        ["8", [], nil]
      ]
    end
  end
end
