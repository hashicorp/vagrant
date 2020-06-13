require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/cloud_init")

describe VagrantPlugins::Kernel_V2::VagrantConfigCloudInit do
  include_context "unit"

  subject { described_class.new(:user_data) }

  let(:provider) { double("provider") }
  let(:machine) { double("machine", name: "rspec", provider: provider,
                         env: Vagrant::Environment.new) }


  def assert_invalid
    errors = subject.validate(machine)
    if errors.empty?
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.empty?
      raise "Errors: #{errors.inspect}"
    end
  end

  before do
    env = double("env")

    subject.content_type = "text/cloud-config"
    subject.inline = <<-CONFIG
    package_update: true
    CONFIG
  end

  describe "#validate" do
    context "with defaults" do
      it "is a valid config" do
        subject.finalize!
        assert_valid
      end

      it "sets a content_type" do
        subject.finalize!
        expect(subject.content_type).to eq("text/cloud-config")
      end

      context "with no type set" do
        let(:type_subject) { described_class.new }

        before do
          type_subject.content_type = "text/cloud-config"
          type_subject.inline = <<-CONFIG
          package_update: true
          CONFIG
        end

        it "defaults to a type" do
          type_subject.finalize!
          expect(type_subject.type).to eq(:user_data)
        end
      end
    end

    context "with an invalid option set" do
      before do
        subject.content_type = "text/not-real-option"
      end

      it "is an invalid config" do
        subject.finalize!
        assert_invalid
      end
    end

    context "with both path and inline set" do
      before do
        subject.path = "path/to/option"
        subject.inline = "package_update: true"
      end

      it "is an invalid config" do
        subject.finalize!
        assert_invalid
      end
    end

    context "with inline set as an invalid type" do
      before do
        subject.path = :i_am_a_symbol
      end

      it "is an invalid config" do
        subject.finalize!
        assert_invalid
      end
    end

    context "with path set as an invalid type" do
      before do
        subject.inline = :i_am_a_symbol
      end

      it "is an invalid config" do
        subject.finalize!
        assert_invalid
      end
    end
  end
end
