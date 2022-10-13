require_relative "../../../base"

require "vagrant/util/platform"

require Vagrant.source_root.join("plugins/providers/docker/config")

describe VagrantPlugins::DockerProvider::Config do
  include_context "unit"

  let(:machine) { double("machine") }

  let(:build_dir) do
    Dir.mktmpdir("vagrant-test-docker-provider-build-dir").tap do |dir|
      File.open(File.join(dir, "Dockerfile"), "wb+") do |f|
        f.write("Hello")
      end
    end
  end

  after do
    FileUtils.rm_rf(build_dir)
  end

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
    subject.image = "foo"
  end

  describe "defaults" do
    before { subject.finalize! }

    its(:build_dir) { should be_nil }
    its(:git_repo) { should be_nil }
    its(:expose) { should eq([]) }
    its(:cmd) { should eq([]) }
    its(:env) { should eq({}) }
    its(:force_host_vm) { should be(false) }
    its(:host_vm_build_dir_options) { should be_nil }
    its(:image) { should be_nil }
    its(:name) { should be_nil }
    its(:privileged) { should be(false) }
    its(:stop_timeout) { should eq(1) }
    its(:vagrant_machine) { should be_nil }
    its(:vagrant_vagrantfile) { should be_nil }

    its(:auth_server) { should be_nil }
    its(:email) { should eq("") }
    its(:username) { should eq("") }
    its(:password) { should eq("") }
  end

  before do
    # By default lets be Linux for validations
    allow(Vagrant::Util::Platform).to receive(:linux).and_return(true)
    allow(Vagrant::Util::Platform).to receive(:linux?).and_return(true)
  end

  describe "should be invalid if any two or more of build dir, git repo and image are set" do
    it "build dir and image" do
      subject.build_dir = build_dir
      subject.image = "foo"
      subject.git_repo = nil
      subject.finalize!
      assert_invalid
    end

    it "build dir and git repo" do
      subject.build_dir = build_dir
      subject.git_repo = "http://example.com/something.git#branch:dir"
      subject.image = nil
      subject.finalize!
      assert_invalid
    end

    it "git repo dir and image" do
      subject.build_dir = nil
      subject.git_repo = "http://example.com/something.git#branch:dir"
      subject.image = "foo"
      subject.finalize!
      assert_invalid
    end

    it "build dir, git repo and image" do
      subject.build_dir = build_dir
      subject.git_repo = "http://example.com/something.git#branch:dir"
      subject.image = "foo"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#build_dir" do
    it "should be valid if not set with image or git repo" do
      subject.build_dir = nil
      subject.git_repo = nil
      subject.image = "foo"
      subject.finalize!
      assert_valid
    end

    it "should be valid with a valid directory" do
      subject.build_dir = build_dir
      subject.finalize!
      assert_valid
    end
  end

  describe "#git_repo" do
    it "should be valid if not set with image or build dir" do
      subject.build_dir = nil
      subject.git_repo = "http://example.com/something.git#branch:dir"
      subject.image = nil
      subject.finalize!
      assert_valid
    end

    it "should be valid with a http git url" do
      subject.git_repo = "http://example.com/something.git#branch:dir"
      subject.finalize!
      assert_valid
    end

    it "should be valid with a git@ url" do
      subject.git_repo = "git@example.com:somebody/something"
      subject.finalize!
      assert_valid
    end

    it "should be valid with a git:// url" do
      subject.git_repo = "git://example.com/something"
      subject.finalize!
      assert_valid
    end

    it "should be valid with a short url beginning with github.com url" do
      subject.git_repo = "github.com/somebody/something"
      subject.finalize!
      assert_valid
    end

    it "should be invalid with an non-git url" do
      subject.git_repo = "http://foo.bar.com"
      subject.finalize!
      assert_invalid
    end

    it "should be invalid with an non url" do
      subject.git_repo = "http||://foo.bar.com sdfs"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#compose" do
    before do
      valid_defaults
    end

    it "should be valid when enabled" do
      subject.compose = true
      subject.finalize!
      assert_valid
    end

    it "should be invalid when force_host_vm is enabled" do
      subject.compose = true
      subject.force_host_vm = true
      subject.finalize!
      assert_invalid
    end
  end

  describe "#create_args" do
    before do
      valid_defaults
    end

    it "is invalid if it isn't an array" do
      subject.create_args = "foo"
      subject.finalize!
      assert_invalid
    end
  end

  describe "#expose" do
    before do
      valid_defaults
    end

    it "uniqs the ports" do
      subject.expose = [1, 1, 4, 5]
      subject.finalize!
      assert_valid

      expect(subject.expose).to eq([1, 4, 5])
    end
  end

  describe "#image" do
    it "should be valid if set" do
      subject.image = "foo"
      subject.finalize!
      assert_valid
    end

    it "should be invalid if not set" do
      subject.image = nil
      subject.finalize!
      assert_invalid
    end
  end

  describe "#link" do
    before do
      valid_defaults
    end

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

    context "#build_dir, #git_repo and #image" do
      it "overrides image if build_dir is set previously" do
        one.build_dir = "foo"
        two.image = "bar"

        expect(subject.build_dir).to be_nil
        expect(subject.image).to eq("bar")
      end

      it "overrides image if git_repo is set previously" do
        one.git_repo = "foo"
        two.image = "bar"

        expect(subject.image).to eq("bar")
        expect(subject.git_repo).to be_nil
      end

      it "overrides build_dir if image is set previously" do
        one.image = "foo"
        two.build_dir = "bar"

        expect(subject.build_dir).to eq("bar")
        expect(subject.image).to be_nil
      end

      it "overrides build_dir if git_repo is set previously" do
        one.git_repo = "foo"
        two.build_dir = "bar"

        expect(subject.build_dir).to eq("bar")
        expect(subject.git_repo).to be_nil
      end

      it "overrides git_repo if build_dir is set previously" do
        one.build_dir = "foo"
        two.git_repo = "bar"

        expect(subject.build_dir).to be_nil
        expect(subject.git_repo).to eq("bar")
      end

      it "overrides git_repo if image is set previously" do
        one.image = "foo"
        two.git_repo = "bar"

        expect(subject.image).to be_nil
        expect(subject.git_repo).to eq("bar")
      end

      it "preserves if both image and build_dir are set" do
        one.image = "foo"
        two.image = "baz"
        two.build_dir = "bar"

        expect(subject.build_dir).to eq("bar")
        expect(subject.image).to eq("baz")
      end

      it "preserves if both image and git_repo are set" do
        one.image = "foo"
        two.image = "baz"
        two.git_repo = "bar"

        expect(subject.image).to eq("baz")
        expect(subject.git_repo).to eq("bar")
      end

      it "preserves if both build_dir and git_repo are set" do
        one.build_dir = "foo"
        two.build_dir = "baz"
        two.git_repo = "bar"

        expect(subject.build_dir).to eq("baz")
        expect(subject.git_repo).to eq("bar")
      end
    end

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

    context "exposed ports" do
      it "merges the exposed ports" do
        one.expose << 1234
        two.expose = [42, 54]

        expect(subject.expose).to eq([
          1234, 42, 54])
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

  describe "#vagrant_machine" do
    before { valid_defaults }

    it "should convert to a symbol" do
      subject.vagrant_machine = "foo"
      subject.finalize!
      assert_valid
      expect(subject.vagrant_machine).to eq(:foo)
    end
  end

  describe "#vagrant_vagrantfile" do
    before { valid_defaults }

    it "should be valid if set to a file" do
      subject.vagrant_vagrantfile = temporary_file.to_s
      subject.finalize!
      assert_valid
    end

    it "should not be valid if set to a non-existent place" do
      subject.vagrant_vagrantfile = "/i/shouldnt/exist"
      subject.finalize!
      assert_invalid
    end
  end
end
