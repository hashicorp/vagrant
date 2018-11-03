require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/puppet/config/puppet")

describe VagrantPlugins::Puppet::Config::Puppet do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  def expect_puts_deprecation_msg(setting)
    expect($stdout).to receive(:puts).with(/DEPRECATION: The '#{setting}'/)
    expect($stdout).to receive(:puts).with(/.*/)
    expect($stdout).to receive(:puts).with(/.*/)
  end

  describe "#finalize!" do
    context "synced_folder_opts is not given" do
      it "sets defaults when no other options are given" do
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:owner => "root", :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_args is given" do
        expect_puts_deprecation_msg("synced_folder_args")
        subject.synced_folder_args = %w[foo]
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:owner => "root", :args => %w[foo], :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_type is given" do
        expect_puts_deprecation_msg("synced_folder_type")
        subject.synced_folder_type = "foo"
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:type => "foo", :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_type and synced_folder_args is given" do
        expect_puts_deprecation_msg("synced_folder_type")
        expect_puts_deprecation_msg("synced_folder_args")
        subject.synced_folder_type = "foo"
        subject.synced_folder_args = %w[foo]
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:type => "foo", :args => %w[foo], :nfs__quiet => true})
      end
    end

    context "synced_folder_opts is given" do
      it "ignores synced_folder_type and synced_folder_args" do
        expect_puts_deprecation_msg("synced_folder_type")
        expect_puts_deprecation_msg("synced_folder_args")
        subject.synced_folder_type = "foo"
        subject.synced_folder_args = %w[foo]
        subject.synced_folder_opts :foo => true, :bar => "baz"
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:foo => true, :bar => "baz"})
      end
    end
  end

end
