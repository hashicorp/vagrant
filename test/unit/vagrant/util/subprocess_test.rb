require File.expand_path("../../../base", __FILE__)
require "vagrant/util/subprocess"

describe Vagrant::Util::Subprocess do
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
  end

  describe "#running?" do
    context "when subprocess has not been started" do
      it "should return false" do
        sp = described_class.new("ls")
        expect(sp.running?).to be(false)
      end
    end
    context "when subprocess has completed" do
      it "should return false" do
        sp = described_class.new("ls")
        sp.execute
        expect(sp.running?).to be(false)
      end
    end
    context "when subprocess is running" do
      it "should return true" do
        sp = described_class.new("sleep", "5")
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
        sp = described_class.new("ls")
        expect(sp.stop).to be(false)
      end
    end

    context "when subprocess has already completed" do
      it "should return false" do
        sp = described_class.new("ls")
        sp.execute
        expect(sp.stop).to be(false)
      end
    end

    context "when subprocess is running" do
      let(:sp){ described_class.new("sleep", "1") }
      it "should return true" do
        thread = Thread.new{ sp.execute }
        sleep(0.1)
        expect(sp.stop).to be(true)
        thread.join
      end

      it "should stop the process" do
        thread = Thread.new{ sp.execute }
        sleep(0.1)
        sp.stop
        expect(sp.running?).to be(false)
        thread.join
      end
    end
  end
end
