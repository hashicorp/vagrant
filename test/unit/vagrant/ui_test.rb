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

  describe "#detail" do
    it "prefixes with spaces" do
      subject.should_receive(:safe_puts).with("    foo", anything)
      subject.detail("foo")
    end

    it "doesn't prefix if told not to" do
      subject.should_receive(:safe_puts).with("foo", anything)
      subject.detail("foo", prefix: false)
    end

    it "prefixes every line" do
      subject.should_receive(:safe_puts).with("    foo\n    bar", anything)
      subject.detail("foo\nbar")
    end
  end

  describe "#output" do
    it "prefixes with ==>" do
      subject.should_receive(:safe_puts).with("==> foo", anything)
      subject.output("foo")
    end

    it "doesn't prefix if told not to" do
      subject.should_receive(:safe_puts).with("foo", anything)
      subject.output("foo", prefix: false)
    end

    it "prefixes every line" do
      subject.should_receive(:safe_puts).with("==> foo\n==> bar", anything)
      subject.output("foo\nbar")
    end
  end

  describe "#scope" do
    it "creates a basic scope" do
      scope = subject.scope("foo")
      expect(scope.scope).to eql("foo")
      expect(scope.ui).to be(subject)
    end
  end
end

describe Vagrant::UI::Colored do
  include_context "unit"

  before do
    # We don't want any prefixes on anything...
    subject.opts[:prefix] = false
  end

  describe "#detail" do
    it "colors output nothing by default" do
      subject.should_receive(:safe_puts).with("foo", anything)
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
    it "colors output nothing by default" do
      subject.should_receive(:safe_puts).with("foo", anything)
      subject.output("foo")
    end

    it "colors output to color specified in global opts" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[1;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo")
    end

    it "colors output to specified color over global opts" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[1;32m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo", color: :green)
    end

    it "doesn't bold the output if specified" do
      subject.opts[:color] = :red

      subject.should_receive(:safe_puts).with do |message, *args|
        expect(message).to start_with("\033[0;31m")
        expect(message).to end_with("\033[0m")
      end

      subject.output("foo", bold: false)
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

describe Vagrant::UI::BasicScope do
  let(:scope) { "foo" }
  let(:ui)    { double("ui") }

  subject { described_class.new(ui, scope) }

  describe "#machine" do
    it "sets the scope option" do
      ui.should_receive(:machine).with(:foo, scope: scope)
      subject.machine(:foo)
    end

    it "preserves existing options" do
      ui.should_receive(:machine).with(:foo, :bar, foo: :bar, scope: scope)
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
    it "prefixes with the scope" do
      ui.should_receive(:output).with("#{scope}: foo", anything)
      subject.output("foo")
    end

    it "does not prefix if told not to" do
      ui.should_receive(:output).with("foo", anything)
      subject.output("foo", prefix: false)
    end

    it "prefixes every line" do
      ui.should_receive(:output).with(
        "#{scope}: foo\n#{scope}: bar", anything)
      subject.output("foo\nbar")
    end

    it "puts the scope into the options hash" do
      ui.should_receive(:output).with(anything, scope: scope)
      subject.output("foo")
    end
  end
end
