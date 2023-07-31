# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)
require "vagrant/util/subprocess"

describe Vagrant::Util::Subprocess do
  let(:ls_test_commands) {[ described_class.new("ls"),  described_class.new("ls", {:detach => true}) ]}
  let(:sleep_test_commands) {[ described_class.new("sleep", "5"), described_class.new("sleep", "5", {:detach => true}) ]}

  describe '#execute' do
    before do
      # ensure we have `cat` and `echo` in our PATH so that we can run these
      # tests successfully.
      ['cat', 'echo'].each do |cmd|
        if !Vagrant::Util::Which.which(cmd)
          pending("cannot run subprocess tests without command #{cmd.inspect}")
        end
      end
    end

    let (:cat) { described_class.new('cat', :notify => [:stdin]) }

    it 'yields the STDIN stream for the process if we set :notify => :stdin' do
      echo = described_class.new('echo', 'hello world', :notify => [:stdin])
      echo.execute do |type, data|
        expect(type).to eq(:stdin)
        expect(data).to be_a(::IO)
      end
    end

    it 'can close STDIN' do
      result = cat.execute do |type, stdin|
        # We should be able to close STDIN without raising an exception
        stdin.close
      end

      # we should exit successfully.
      expect(result.exit_code).to eq(0)
    end

    it 'can write to STDIN correctly' do
      data = "hello world\n"
      result = cat.execute do |type, stdin|
        stdin.write(data)
        stdin.close
      end

      # we should exit successfully.
      expect(result.exit_code).to eq(0)

      # we should see our data as the output from `cat`
      expect(result.stdout).to eq(data)
    end

    it 'does not wait for process if detach option specified' do
      cat = described_class.new('cat', {:detach => true})
      expect(cat.execute).to eq(nil)
    end

    context "running within AppImage" do
      let(:appimage_ld_path) { nil }
      let(:exec_path) { "/exec/path" }
      let(:appimage_path) { "/appimage" }
      let(:process) { double("process", io: process_io, environment: process_env) }
      let(:process_io) { double("process_io") }
      let(:process_env) { double("process_env") }
      let(:subject) { described_class.new(exec_path) }

      before do
        allow(process).to receive(:start)
        allow(process).to receive(:duplex=)
        allow(process).to receive(:alive?).and_return(false)
        allow(process).to receive(:exited?).and_return(true)
        allow(process).to receive(:poll_for_exit).and_return(0)
        allow(process).to receive(:exit_code).and_return(0)
        allow(process_io).to receive(:stdout=)
        allow(process_io).to receive(:stderr=)
        allow(process_io).to receive(:stdin).and_return(double("io_stdin", "sync=" => true))
        allow(process_env).to receive(:[]=)
        allow(ENV).to receive(:[]).with("VAGRANT_INSTALLER_ENV").and_return("1")
        allow(ENV).to receive(:[]).with("VAGRANT_APPIMAGE").and_return("1")
        allow(ENV).to receive(:[]).with("VAGRANT_APPIMAGE_HOST_LD_LIBRARY_PATH").and_return(appimage_ld_path)
        allow(File).to receive(:file?).with(exec_path).and_return(true)
        allow(ChildProcess).to receive(:build).and_return(process)
        allow(Vagrant).to receive(:installer_embedded_dir).and_return(appimage_path)
        allow(Vagrant).to receive(:user_data_path).and_return("")
        allow(Vagrant::Util::Platform).to receive(:darwin?).and_return(false)
      end

      after { subject.execute }

      it "should not update LD_LIBRARY_PATH when environment variable is not set" do
        expect(process_env).not_to receive(:[]=).with("LD_LIBRARY_PATH", anything)
      end

      context "when APPIMAGE_LD_LIBRARY_PATH environment variable is set" do
        let(:appimage_ld_path) { "APPIMAGE_SYSTEM_LIBS" }

        it "should set LD_LIBRARY_PATH when executable is not within appimage" do
          expect(process_env).to receive(:[]=).with("LD_LIBRARY_PATH", appimage_ld_path)
        end

        context "when executable is located within AppImage" do
          let(:exec_path) { "#{appimage_path}/exec/path" }

          it "should not set LD_LIBRARY_PATH" do
            expect(process_env).not_to receive(:[]=).with("LD_LIBRARY_PATH", anything)
          end
        end
      end
    end
  end

  describe "#running?" do
    it "should return false when subprocess has not been started" do
      ls_test_commands.each do |sp|
        expect(sp.running?).to be(false)
      end
    end

    it "should return false when subprocess has completed" do
      ls_test_commands.each do |sp|
        sp.execute
        sleep(0.1)
        expect(sp.running?).to be(false)
      end
    end

    it "should return true when subprocess is running" do
      sleep_test_commands.each do |sp|
        thread = Thread.new{ sp.execute }
        sleep(0.3)
        expect(sp.running?).to be(true)
        sp.stop
        thread.join
      end
    end
  end

  describe "#stop" do
    context "when subprocess has not been started" do
      it "should return false" do
        ls_test_commands.each do |sp|
          expect(sp.stop).to be(false)
        end
      end
    end

    context "when subprocess has already completed" do
      it "should return false" do
        ls_test_commands.each do |sp|
          sp.execute
          sleep(0.1)
          expect(sp.stop).to be(false)
        end
      end
    end

    context "when subprocess is running" do
      it "should return true" do
        sleep_test_commands.each do |sp|
          thread = Thread.new{ sp.execute }
          sleep(0.1)
          expect(sp.stop).to be(true)
          thread.join
        end
      end

      it "should stop the process" do
        sleep_test_commands.each do |sp|
          thread = Thread.new{ sp.execute }
          sleep(0.1)
          sp.stop
          expect(sp.running?).to be(false)
          thread.join
        end
      end
    end
  end
end
