require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/providers/docker/config")

describe VagrantPlugins::DockerProvider::Config do
  let(:machine) { double("machine") }

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

  describe "defaults" do
    before { subject.finalize! }

    its(:cmd) { should eq([]) }
    its(:env) { should eq({}) }
    its(:image) { should be_nil }
    its(:privileged) { should be_false }
    its(:vagrant_machine) { should be_nil }
    its(:vagrant_vagrantfile) { should be_nil }
  end

  before do
    # By default lets be Linux for validations
    Vagrant::Util::Platform.stub(linux: true)
  end

  it "should be valid by default" do
    subject.finalize!
    assert_valid
  end

  describe "#link" do
    it "should be valid with good links" do
      subject.link "foo:bar"
      subject.link "db:blah"
      subject.finalize!
      assert_valid
    end

    it "should be invalid if not name:alias" do
      subject.link "foo"
      subject.finalize!
      assert_invalid
    end

    it "should be invalid if too many colons" do
      subject.link "foo:bar:baz"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#merge" do
    let(:one) { described_class.new }
    let(:two) { described_class.new }

    subject { one.merge(two) }

    context "env vars" do
      it "should merge the values" do
        one.env["foo"] = "bar"
        two.env["bar"] = "baz"

        expect(subject.env).to eq({
          "foo" => "bar",
          "bar" => "baz",
        })
      end
    end

    context "links" do
      it "should merge the links" do
        one.link "foo"
        two.link "bar"

        expect(subject._links).to eq([
          "foo", "bar"])
      end
    end
  end
end
