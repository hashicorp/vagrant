# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)
require "vagrant/util/line_buffer"

describe Vagrant::Util::LineBuffer do
  it "should raise error when no callback is provided" do
    expect { subject }.to raise_error(ArgumentError)
  end

  context "with block defined" do
    let(:block) { proc{ |l| output << l } }
    let(:output) { [] }
    let(:partial) { "this is part of a line. " }
    let(:line) { "this is a full line\n" }

    subject { described_class.new(&block) }

    it "should not raise an error when callback is provided" do
      expect { subject }.not_to raise_error
    end

    describe "#<<" do
      it "should add line to the output" do
        subject << line
        expect(output).to eq([line.rstrip])
      end

      it "should not add partial line to output" do
        subject << partial
        expect(output).to be_empty
      end

      it "should add partial line to output once full line is given" do
        subject << partial
        expect(output).to be_empty
        subject << line
        expect(output).to eq([partial + line.rstrip])
      end

      it "should add line once it has surpassed max line length" do
        overflow = "a" * (described_class.const_get(:MAX_LINE_LENGTH) + 1)
        subject << overflow
        expect(output).to eq([overflow])
      end
    end

    describe "#close" do
      it "should output any partial data left in buffer" do
        subject << partial
        expect(output).to be_empty
        subject.close
        expect(output).to eq([partial])
      end

      it "should not be writable after closing" do
        subject.close
        expect { subject << partial }.to raise_error(FrozenError)
      end
    end
  end
end
