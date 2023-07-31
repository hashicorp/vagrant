# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

# -*- coding: utf-8 -*-
require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/io'

describe Vagrant::Util::IO do
  describe ".read_until_block" do
    let(:io) { double("io") }

    before do
      # Ensure that we don't get stuck in a loop
      allow(io).to receive(:read_nonblock).and_raise(EOFError)
      allow(io).to receive(:readpartial).and_raise(EOFError)
    end

    context "on non-Windows system" do
      before { allow(Vagrant::Util::Platform).to receive(:windows?).
          and_return(false) }

      it "should use a non-blocking read" do
        expect(io).to receive(:read_nonblock).and_return("")
        described_class.read_until_block(io)
      end

      it "should receive data until breakable event" do
        expect(io).to receive(:read_nonblock).and_return("one")
        expect(io).to receive(:read_nonblock).and_return("two")
        expect(io).to receive(:read_nonblock).and_return("three")
        data = described_class.read_until_block(io)
        expect(data).to eq("onetwothree")
      end

      context "with breakable errors" do
        [EOFError, Errno::EAGAIN, IO::EAGAINWaitReadable, IO::EINPROGRESSWaitReadable, IO::EWOULDBLOCKWaitReadable].each do |err_class|
          it "should break without error on #{err_class}" do
            expect(io).to receive(:read_nonblock).and_raise(err_class)
            expect(described_class.read_until_block(io)).to be_empty
          end
        end
      end

      context "with non-breakable errors" do
        it "should raise the error" do
          expect(io).to receive(:read_nonblock).and_raise(StandardError)
          expect { described_class.read_until_block(io) }.to raise_error(StandardError)
        end
      end
    end

    context "on Windows system" do
      before do
        allow(Vagrant::Util::Platform).to receive(:windows?).
          and_return(true)
        allow(IO).to receive(:select).with([io], any_args).
          and_return([io])
        allow(io).to receive(:empty?).and_return(false)
      end

      it "should use select" do
        expect(IO).to receive(:select).with([io], any_args)
        described_class.read_until_block(io)
      end

      it "should receive data until breakable event" do
        expect(io).to receive(:readpartial).and_return("one")
        expect(io).to receive(:readpartial).and_return("two")
        expect(io).to receive(:readpartial).and_return("three")
        data = described_class.read_until_block(io)
        expect(data).to eq("onetwothree")
      end

      context "with breakable errors" do
        [EOFError, Errno::EAGAIN, IO::EAGAINWaitReadable, IO::EINPROGRESSWaitReadable,
          IO::EWOULDBLOCKWaitReadable].each do |err_class|
          it "should break without error on #{err_class}" do
            expect(io).to receive(:readpartial).and_raise(err_class)
            expect(described_class.read_until_block(io)).to be_empty
          end
        end
      end

      context "with non-breakable errors" do
        it "should raise the error" do
          expect(io).to receive(:readpartial).and_raise(StandardError)
          expect { described_class.read_until_block(io) }.to raise_error(StandardError)
        end
      end

      context "encoding" do
        let(:output) { "output".force_encoding("ASCII-8BIT") }

        before { expect(io).to receive(:readpartial).and_return(output) }

        it "should encode output to UTF-8" do
          expect(described_class.read_until_block(io).encoding.name).to eq("UTF-8")
        end

        context "when output includes characters with undefined conversion" do
          let(:output) { "output\xFF".force_encoding("ASCII-8BIT") }

          before { expect(Encoding).to receive(:default_external).
              and_return(Encoding.find("ASCII-8BIT")) }

          it "should return data with invalid characters replaced" do
            expect(described_class.read_until_block(io)).to include("�")
          end
        end
      end
    end
  end
end
