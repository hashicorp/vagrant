require File.expand_path("../../base", __FILE__)

describe Vagrant::UI::Basic do
  context "in general" do
    it "outputs within the a new thread" do
      current = Thread.current.object_id

      subject.should_receive(:safe_puts).with do |*args|
        expect(Thread.current.object_id).to_not eq(current)
        true
      end

      subject.output("foo")
    end

    it "outputs using `puts` by default" do
      subject.should_receive(:safe_puts).with do |message, **opts|
        expect(opts[:printer]).to eq(:puts)
        true
      end

      subject.output("foo")
    end

    it "outputs using `print` if new_line is false" do
      subject.should_receive(:safe_puts).with do |message, **opts|
        expect(opts[:printer]).to eq(:print)
        true
      end

      subject.output("foo", new_line: false)
    end

    it "outputs using `print` if new_line is false" do
      subject.should_receive(:safe_puts).with do |message, **opts|
        expect(opts[:printer]).to eq(:print)
        true
      end

      subject.output("foo", new_line: false)
    end

    it "outputs to stdout" do
      subject.should_receive(:safe_puts).with do |message, **opts|
        expect(opts[:io]).to be($stdout)
        true
      end

      subject.output("foo")
    end

    it "outputs to stderr for errors" do
      subject.should_receive(:safe_puts).with do |message, **opts|
        expect(opts[:io]).to be($stderr)
        true
      end

      subject.error("foo")
    end
  end
end

describe Vagrant::UI::Colored do
  include_context "unit"

  describe "#detail" do
    it "colors output nothing by default" do
      subject.should_receive(:safe_puts).with("\033[0mfoo\033[0m", anything)
      subject.detail("foo")
    end

    it "does not bold by default with a color" do
      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.detail("foo", color: :red)
    end
  end

  describe "#error" do
    it "colors red" do
      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.error("foo")
    end
  end

  describe "#output" do
    it "colors output nothing by default, no bold" do
      subject.should_receive(:safe_puts).with("\033[0mfoo\033[0m", anything)
      subject.output("foo")
    end

    it "bolds output without color if specified" do
      subject.should_receive(:safe_puts).with("\033[1mfoo\033[0m", anything)
      subject.output("foo", bold: true)
    end

    it "colors output to color specified in global opts" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo")
    end

    it "colors output to specified color over global opts" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;32m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo", color: :green)
    end

    it "bolds the output if specified" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[1;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo", bold: true)
    end
  end

  describe "#success" do
    it "colors green" do
      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;32m")
        expect(message).to end_with("\033[0m")
      end

      subject.success("foo")
    end
  end

  describe "#warn" do
    it "colors yellow" do
      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;33m")
        expect(message).to end_with("\033[0m")
      end

      subject.warn("foo")
    end
  end
end

describe Vagrant::UI::MachineReadable do
  describe "#ask" do
    it "raises an exception" do
      expect { subject.ask("foo") }.
        to raise_error(Vagrant::Errors::UIExpectsTTY)
    end
  end

  describe "#machine" do
    it "is formatted properly" do
      subject.should_receive(:safe_puts).with do |message|
        parts = message.split(",")
        expect(parts.length).to eq(5)
        expect(parts[1]).to eq("")
        expect(parts[2]).to eq("type")
        expect(parts[3]).to eq("data")
        expect(parts[4]).to eq("another")
        true
      end

      subject.machine(:type, "data", "another")
    end

    it "includes a target if given" do
      subject.should_receive(:safe_puts).with do |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[1]).to eq("boom")
        expect(parts[2]).to eq("type")
        expect(parts[3]).to eq("data")
        true
      end

      subject.machine(:type, "data", target: "boom")
    end

    it "replaces commas" do
      subject.should_receive(:safe_puts).with do |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo%!(VAGRANT_COMMA)bar")
        true
      end

      subject.machine(:type, "foo,bar")
    end

    it "replaces newlines" do
      subject.should_receive(:safe_puts).with do |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo\\nbar\\r")
        true
      end

      subject.machine(:type, "foo\nbar\r")
    end

    # This is for a bug where JSON parses are frozen and an
    # exception was being raised.
    it "works properly with frozen string arguments" do
      subject.should_receive(:safe_puts).with do |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo\\nbar\\r")
        true
      end

      subject.machine(:type, "foo\nbar\r".freeze)
    end
  end
end

describe Vagrant::UI::Prefixed do
  let(:prefix) { "foo" }
  let(:ui)     { Vagrant::UI::Basic.new }

  subject { described_class.new(ui, prefix) }

  describe "#ask" do
    it "does not request bolding" do
      ui.should_receive(:ask).with("    #{prefix}: foo", bold: false)
      subject.ask("foo")
    end
  end

  describe "#detail" do
    it "prefixes with spaces and the message" do
      ui.should_receive(:safe_puts).with("    #{prefix}: foo", anything)
      subject.detail("foo")
    end

    it "prefixes every line" do
      ui.should_receive(:detail).with("    #{prefix}: foo\n    #{prefix}: bar", bold: false)
      subject.detail("foo\nbar")
    end

    it "doesn't prefix if requestsed" do
      ui.should_receive(:detail).with("foo", prefix: false, bold: false)
      subject.detail("foo", prefix: false)
    end
  end

  describe "#machine" do
    it "sets the target option" do
      ui.should_receive(:machine).with(:foo, target: prefix)
      subject.machine(:foo)
    end

    it "preserves existing options" do
      ui.should_receive(:machine).with(:foo, :bar, foo: :bar, target: prefix)
      subject.machine(:foo, :bar, foo: :bar)
    end
  end

  describe "#opts" do
    it "is the parent's opts" do
      ui.stub(opts: Object.new)
      expect(subject.opts).to be(ui.opts)
    end
  end

  describe "#output" do
    it "prefixes with an arrow and the message" do
      ui.should_receive(:output).with("==> #{prefix}: foo", anything)
      subject.output("foo")
    end

    it "prefixes every line" do
      ui.should_receive(:output).with("==> #{prefix}: foo\n==> #{prefix}: bar", anything)
      subject.output("foo\nbar")
    end

    it "doesn't prefix if requestsed" do
      ui.should_receive(:output).with("foo", prefix: false, bold: true)
      subject.output("foo", prefix: false)
    end

    it "requests bolding" do
      ui.should_receive(:output).with("==> #{prefix}: foo", bold: true)
      subject.output("foo")
    end
  end
end
