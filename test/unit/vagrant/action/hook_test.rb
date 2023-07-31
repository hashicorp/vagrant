# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/action/builder"
require "vagrant/action/hook"

describe Vagrant::Action::Hook do
  describe "defaults" do
    describe '#after_hooks' do
      subject { super().after_hooks }
      it   { should be_empty }
    end

    describe '#before_hooks' do
      subject { super().before_hooks }
      it  { should be_empty }
    end

    describe '#append_hooks' do
      subject { super().append_hooks }
      it  { should be_empty }
    end

    describe '#prepend_hooks' do
      subject { super().prepend_hooks }
      it { should be_empty }
    end
  end

  describe "before hooks" do
    let(:existing) { "foo" }

    it "should append them" do
      block = Proc.new {}

      subject.before(existing, 1)
      subject.before(existing, 2)
      subject.before(existing, 3, :arg, &block)

      hooks = subject.before_hooks[existing]
      expect(hooks.size).to eq(3)
      expect(hooks[0].middleware).to eq(1)
      expect(hooks[0].arguments.parameters).to eq([])
      expect(hooks[0].arguments.keywords).to eq({})
      expect(hooks[0].arguments.block).to be_nil
      expect(hooks[1].middleware).to eq(2)
      expect(hooks[1].arguments.parameters).to eq([])
      expect(hooks[1].arguments.keywords).to eq({})
      expect(hooks[1].arguments.block).to be_nil
      expect(hooks[2].middleware).to eq(3)
      expect(hooks[2].arguments.parameters).to eq([:arg])
      expect(hooks[2].arguments.keywords).to eq({})
      expect(hooks[2].arguments.block).to eq(block)
    end
  end

  describe "after hooks" do
    let(:existing) { "foo" }

    it "should append them" do
      block = Proc.new {}

      subject.after(existing, 1)
      subject.after(existing, 2)
      subject.after(existing, 3, :arg, &block)

      hooks = subject.after_hooks[existing]
      expect(hooks.size).to eq(3)
      expect(hooks[0].middleware).to eq(1)
      expect(hooks[0].arguments.parameters).to eq([])
      expect(hooks[0].arguments.keywords).to eq({})
      expect(hooks[0].arguments.block).to be_nil
      expect(hooks[1].middleware).to eq(2)
      expect(hooks[1].arguments.parameters).to eq([])
      expect(hooks[1].arguments.keywords).to eq({})
      expect(hooks[1].arguments.block).to be_nil
      expect(hooks[2].middleware).to eq(3)
      expect(hooks[2].arguments.parameters).to eq([:arg])
      expect(hooks[2].arguments.keywords).to eq({})
      expect(hooks[2].arguments.block).to eq(block)
    end
  end

  describe "append" do
    it "should make a list" do
      block = Proc.new {}

      subject.append(1)
      subject.append(2)
      subject.append(3, :arg, &block)

      hooks = subject.append_hooks
      expect(hooks.size).to eq(3)
      expect(hooks[0].middleware).to eq(1)
      expect(hooks[0].arguments.parameters).to eq([])
      expect(hooks[0].arguments.keywords).to eq({})
      expect(hooks[0].arguments.block).to be_nil
      expect(hooks[1].middleware).to eq(2)
      expect(hooks[1].arguments.parameters).to eq([])
      expect(hooks[1].arguments.keywords).to eq({})
      expect(hooks[1].arguments.block).to be_nil
      expect(hooks[2].middleware).to eq(3)
      expect(hooks[2].arguments.parameters).to eq([:arg])
      expect(hooks[2].arguments.keywords).to eq({})
      expect(hooks[2].arguments.block).to eq(block)
    end
  end

  describe "prepend" do
    it "should make a list" do
      block = Proc.new {}

      subject.prepend(1)
      subject.prepend(2)
      subject.prepend(3, :arg, &block)

      hooks = subject.prepend_hooks
      expect(hooks.size).to eq(3)
      expect(hooks[0].middleware).to eq(1)
      expect(hooks[0].arguments.parameters).to eq([])
      expect(hooks[0].arguments.keywords).to eq({})
      expect(hooks[0].arguments.block).to be_nil
      expect(hooks[1].middleware).to eq(2)
      expect(hooks[1].arguments.parameters).to eq([])
      expect(hooks[1].arguments.keywords).to eq({})
      expect(hooks[1].arguments.block).to be_nil
      expect(hooks[2].middleware).to eq(3)
      expect(hooks[2].arguments.parameters).to eq([:arg])
      expect(hooks[2].arguments.keywords).to eq({})
      expect(hooks[2].arguments.block).to eq(block)
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

      stack = builder.stack
      expect(stack[0].middleware).to eq("1")
      expect(stack[0].arguments.parameters).to eq([2])
      expect(stack[1].middleware).to eq("2")
      expect(stack[1].arguments.parameters).to eq([])
      expect(stack[2].middleware).to eq("8")
      expect(stack[2].arguments.parameters).to eq([])
      expect(stack[3].middleware).to eq("9")
      expect(stack[3].arguments.parameters).to eq([])
    end

    it "should not prepend or append if disabled" do
      builder.use("3")
      builder.use("8")

      subject.prepend("1", 2)
      subject.append("9")
      subject.after("3", "4")
      subject.before("8", "7")

      subject.apply(builder, no_prepend_or_append: true)

      stack = builder.stack
      expect(stack[0].middleware).to eq("3")
      expect(stack[1].middleware).to eq("4")
      expect(stack[2].middleware).to eq("7")
      expect(stack[3].middleware).to eq("8")
    end
  end
end
