require_relative "../../../base"

require Vagrant.source_root.join("plugins/pushes/harmony/config")

describe VagrantPlugins::HarmonyPush::Config do
  include_context "unit"

  let(:machine) { double("machine") }

  # For testing merging
  let(:one) { described_class.new }
  let(:two) { described_class.new }

  def assert_invalid
    errors = subject.validate(machine)
    if !errors.values.any? { |v| !v.empty? }
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.values.all? { |v| v.empty? }
      raise "Errors: #{errors.inspect}"
    end
  end

  def valid_defaults
  end

  describe "defaults" do
    before { subject.finalize! }

    its(:app) { should be_nil }
    its(:dir) { should eq(".") }
    its(:exclude) { should be_empty }
    its(:include) { should be_empty }
    its(:uploader_path) { should be_nil }
    its(:vcs) { should be_true }
  end

  describe "app" do
    before do
      valid_defaults
    end

    it "is invalid if not set" do
      subject.app = ""
      subject.finalize!
      assert_invalid
    end

    it "is valid if set" do
      subject.app = "foo/bar"
      subject.finalize!
      assert_valid
    end
  end

  describe "exclude" do
    context "merge" do
      subject { one.merge(two) }

      it "appends" do
        one.exclude = ["foo"]
        two.exclude = ["bar"]

        expect(subject.exclude).to eq(["foo", "bar"])
      end
    end
  end

  describe "include" do
    context "merge" do
      subject { one.merge(two) }

      it "appends" do
        one.include = ["foo"]
        two.include = ["bar"]

        expect(subject.include).to eq(["foo", "bar"])
      end
    end
  end
end
