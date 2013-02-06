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
      subject.before(existing, 1)
      subject.before(existing, 2)

      subject.before_hooks[existing].should == [1, 2]
    end
  end

  describe "after hooks" do
    let(:existing) { "foo" }

    it "should append them" do
      subject.after(existing, 1)
      subject.after(existing, 2)

      subject.after_hooks[existing].should == [1, 2]
    end
  end

  describe "append" do
    it "should make a list" do
      subject.append(1)
      subject.append(2)

      subject.append_hooks.should == [1, 2]
    end
  end

  describe "prepend" do
    it "should make a list" do
      subject.prepend(1)
      subject.prepend(2)

      subject.prepend_hooks.should == [1, 2]
    end
  end

  describe "applying" do
    let(:builder) { Vagrant::Action::Builder.new }

    it "should build the proper stack" do
      subject.prepend("1")
      subject.append("9")
      subject.after("1", "2")
      subject.before("9", "8")

      subject.apply(builder)

      builder.stack.map(&:first).should == %w[1 2 8 9]
    end
  end
end
