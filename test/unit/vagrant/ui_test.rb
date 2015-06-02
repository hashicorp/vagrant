require File.expand_path("../../base", __FILE__)

describe Vagrant::UI::Basic do
  context "in general" do
    it "outputs within the a new thread" do
      current = Thread.current.object_id

      expect(subject).to receive(:safe_puts).with { |*args|
        expect(Thread.current.object_id).to_not eq(current)
        true
      }

      subject.output("foo")
    end

    it "outputs using `puts` by default" do
      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(opts[:printer]).to eq(:puts)
        true
      }

      subject.output("foo")
    end

    it "outputs using `print` if new_line is false" do
      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(opts[:printer]).to eq(:print)
        true
      }

      subject.output("foo", new_line: false)
    end

    it "outputs using `print` if new_line is false" do
      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(opts[:printer]).to eq(:print)
        true
      }

      subject.output("foo", new_line: false)
    end

    it "outputs to the assigned stdout" do
      stdout = StringIO.new
      subject.stdout = stdout

      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(opts[:io]).to be(stdout)
        true
      }

      subject.output("foo")
    end

    it "outputs to stdout by default" do
      expect(subject.stdout).to be($stdout)
    end

    it "outputs to the assigned stderr for errors" do
      stderr = StringIO.new
      subject.stderr = stderr

      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(opts[:io]).to be(stderr)
        true
      }

      subject.error("foo")
    end

    it "outputs to stderr for errors by default" do
      expect(subject.stderr).to be($stderr)
    end
  end

  context "#color?" do
    it "returns false" do
      expect(subject.color?).to be(false)
    end
  end

  context "#detail" do
    it "outputs details" do
      expect(subject).to receive(:safe_puts).with { |message, **opts|
        expect(message).to eq("foo")
        true
      }

      subject.detail("foo")
    end

    it "doesn't output details if disabled" do
      expect(subject).to receive(:safe_puts).never

      subject.opts[:hide_detail] = true
      subject.detail("foo")
    end
  end
end

describe Vagrant::UI::Colored do
  include_context "unit"

  describe "#color?" do
    it "returns true" do
      expect(subject.color?).to be(true)
    end
  end

  describe "#detail" do
    it "colors output nothing by default" do
      expect(subject).to receive(:safe_puts).with("\033[0mfoo\033[0m", anything)
      subject.detail("foo")
    end

    it "does not bold by default with a color" do
      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      }

      subject.detail("foo", color: :red)
    end
  end

  describe "#error" do
    it "colors red" do
      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      }

      subject.error("foo")
    end
  end

  describe "#output" do
    it "colors output nothing by default, no bold" do
      expect(subject).to receive(:safe_puts).with("\033[0mfoo\033[0m", anything)
      subject.output("foo")
    end

    it "doesn't use a color if default color" do
      expect(subject).to receive(:safe_puts).with("\033[0mfoo\033[0m", anything)
      subject.output("foo", color: :default)
    end

    it "bolds output without color if specified" do
      expect(subject).to receive(:safe_puts).with("\033[1mfoo\033[0m", anything)
      subject.output("foo", bold: true)
    end

    it "colors output to color specified in global opts" do
      subject.opts[:color] = :red

      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      }

      subject.output("foo")
    end

    it "colors output to specified color over global opts" do
      subject.opts[:color] = :red

      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;32m")
        expect(message).to end_with("\033[0m")
      }

      subject.output("foo", color: :green)
    end

    it "bolds the output if specified" do
      subject.opts[:color] = :red

      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[1;31m")
        expect(message).to end_with("\033[0m")
      }

      subject.output("foo", bold: true)
    end
  end

  describe "#success" do
    it "colors green" do
      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;32m")
        expect(message).to end_with("\033[0m")
      }

      subject.success("foo")
    end
  end

  describe "#warn" do
    it "colors yellow" do
      expect(subject).to receive(:safe_puts).with { |message, *args|
        expect(message).to start_with("\033[0;33m")
        expect(message).to end_with("\033[0m")
      }

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
      expect(subject).to receive(:safe_puts).with { |message|
        parts = message.split(",")
        expect(parts.length).to eq(5)
        expect(parts[1]).to eq("")
        expect(parts[2]).to eq("type")
        expect(parts[3]).to eq("data")
        expect(parts[4]).to eq("another")
        true
      }

      subject.machine(:type, "data", "another")
    end

    it "includes a target if given" do
      expect(subject).to receive(:safe_puts).with { |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[1]).to eq("boom")
        expect(parts[2]).to eq("type")
        expect(parts[3]).to eq("data")
        true
      }

      subject.machine(:type, "data", target: "boom")
    end

    it "replaces commas" do
      expect(subject).to receive(:safe_puts).with { |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo%!(VAGRANT_COMMA)bar")
        true
      }

      subject.machine(:type, "foo,bar")
    end

    it "replaces newlines" do
      expect(subject).to receive(:safe_puts).with { |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo\\nbar\\r")
        true
      }

      subject.machine(:type, "foo\nbar\r")
    end

    # This is for a bug where JSON parses are frozen and an
    # exception was being raised.
    it "works properly with frozen string arguments" do
      expect(subject).to receive(:safe_puts).with { |message|
        parts = message.split(",")
        expect(parts.length).to eq(4)
        expect(parts[3]).to eq("foo\\nbar\\r")
        true
      }

      subject.machine(:type, "foo\nbar\r".freeze)
    end
  end
end

describe Vagrant::UI::Prefixed do
  let(:prefix) { "foo" }
  let(:ui)     { Vagrant::UI::Basic.new }

  subject { described_class.new(ui, prefix) }

  describe "#initialize_copy" do
    it "duplicates the underlying ui too" do
      another = subject.dup
      expect(another.opts).to_not equal(subject.opts)
    end
  end

  describe "#ask" do
    it "does not request bolding" do
      expect(ui).to receive(:ask).with("    #{prefix}: foo", bold: false)
      subject.ask("foo")
    end
  end

  describe "#detail" do
    it "prefixes with spaces and the message" do
      expect(ui).to receive(:safe_puts).with("    #{prefix}: foo", anything)
      subject.detail("foo")
    end

    it "prefixes every line" do
      expect(ui).to receive(:detail).with("    #{prefix}: foo\n    #{prefix}: bar", bold: false)
      subject.detail("foo\nbar")
    end

    it "doesn't prefix if requested" do
      expect(ui).to receive(:detail).with("foo", prefix: false, bold: false)
      subject.detail("foo", prefix: false)
    end
  end

  describe "#machine" do
    it "sets the target option" do
      expect(ui).to receive(:machine).with(:foo, target: prefix)
      subject.machine(:foo)
    end

    it "preserves existing options" do
      expect(ui).to receive(:machine).with(:foo, :bar, foo: :bar, target: prefix)
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
      expect(ui).to receive(:output).with("==> #{prefix}: foo", anything)
      subject.output("foo")
    end

    it "prefixes with spaces if requested" do
      expect(ui).to receive(:output).with("    #{prefix}: foo", anything)
      subject.output("foo", prefix_spaces: true)
    end

    it "prefixes every line" do
      expect(ui).to receive(:output).with("==> #{prefix}: foo\n==> #{prefix}: bar", anything)
      subject.output("foo\nbar")
    end

    it "doesn't prefix if requestsed" do
      expect(ui).to receive(:output).with("foo", prefix: false, bold: true)
      subject.output("foo", prefix: false)
    end

    it "requests bolding" do
      expect(ui).to receive(:output).with("==> #{prefix}: foo", bold: true)
      subject.output("foo")
    end

    it "does not request bolding if class-level disabled" do
      ui.opts[:bold] = false
      expect(ui).to receive(:output).with("==> #{prefix}: foo", {})
      subject.output("foo")
    end

    it "prefixes with another prefix if requested" do
      expect(ui).to receive(:output).with("==> bar: foo", anything)
      subject.output("foo", target: "bar")
    end
  end
end
