require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/puppet/config/puppet")

describe VagrantPlugins::Puppet::Config::Puppet do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine", ui: double("ui"), env: double("env", root_path: "")) }

  def puppet_msg(key, options = {})
    I18n.t("vagrant.provisioners.puppet.#{key}", options)
  end
  def expect_deprecation_warning(setting)
    expect(machine.ui).to receive(:warn).with(puppet_msg("#{setting}_deprecation"))
  end
  def expect_no_deprecation_warning(setting)
    expect(machine.ui).not_to receive(:warn).with(puppet_msg("#{setting}_deprecation"))
  end

  describe "#synced_folder_opts setter" do
    [:nfs, :rsync, :smb, :virtualbox].each do |symbol|
      it "should map synced_folder symbol :#{symbol} to :type" do
        subject.synced_folder_opts symbol => symbol.to_s
        expect(subject.synced_folder_opts[:type]).to eql(symbol.to_s)
      end
    end
    it "should not change single given type" do
      subject.synced_folder_opts :type => "foo"
      expect(subject.synced_folder_opts[:type]).to eql("foo")
    end
    it "lets the given type symbol overwrite type" do
      subject.synced_folder_opts :type => "foo", :nfs => true
      expect(subject.synced_folder_opts[:type]).to eql("nfs")

      subject.synced_folder_opts :nfs => true, :type => "foo"
      expect(subject.synced_folder_opts[:type]).to eql("nfs")
    end
  end

  describe "#finalize!" do
    context "synced_folder_opts is not given" do
      it "sets defaults when no other options are given" do
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:owner => "root", :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_args is given" do
        subject.synced_folder_args = %w[foo]
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:owner => "root", :args => %w[foo], :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_type is given" do
        subject.synced_folder_type = "foo"
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:type => "foo", :nfs__quiet => true})
      end
      it "sets defaults when synced_folder_type and synced_folder_args is given" do
        subject.synced_folder_type = "foo"
        subject.synced_folder_args = %w[foo]
        subject.finalize!
        expect(subject.synced_folder_opts).to \
          eql({:type => "foo", :args => %w[foo], :nfs__quiet => true})
      end
    end

    context "synced_folder_opts is given" do
      it "should be able to assign hash" do
        subject.synced_folder_opts = { foo: true }
        subject.finalize!
        expect(subject.synced_folder_opts[:foo]).to eql(true)
      end
      it "should set from function parameters" do
        subject.synced_folder_opts :foo => true
        subject.finalize!
        expect(subject.synced_folder_opts[:foo]).to eql(true)
      end
      it "does merge synced_folder_type if it does not collide" do
        subject.synced_folder_opts :foo => true, :bar => true
        subject.synced_folder_type = "foo"
        subject.finalize!
        expect(subject.synced_folder_opts[:type]).to eql("foo")
      end
      [:nfs, :rsync, :smb, :virtualbox, :type].each do |symbol|
        it "does not merge synced_folder_type if it collides with synced_folder_opts[:#{symbol.to_s}]" do
          subject.synced_folder_opts symbol => symbol.to_s
          subject.synced_folder_type = "foo"
          subject.finalize!
          expect(subject.synced_folder_opts[symbol]).to eql(symbol.to_s)
        end
      end
      [:rsync, :type].each do |symbol|
        it "does merge synced_folder_args if it does not collide with synced_folder_opts[:#{symbol.to_s}]" do
          subject.synced_folder_opts symbol => "rsync"
          subject.synced_folder_args = "foo"
          subject.finalize!
          expect(subject.synced_folder_opts[:args]).to eql("foo")
        end
      end
    end
  end

  describe "#validate" do
    let(:result) { subject.validate(machine) }
    let(:errors) { result["puppet provisioner"] }
    before do
      subject.module_path = ""
      subject.manifests_path = [:host, "manifests"];
    end
    it "does not warn when synced_folder_type is not set" do
      expect_no_deprecation_warning("synced_folder_type")
      subject.validate(machine)
    end
    it "does not warn when synced_folder_args is not set" do
      expect_no_deprecation_warning("synced_folder_args")
      subject.validate(machine)
    end
    it "does warn about deprecation when synced_folder_type is set" do
      expect_deprecation_warning("synced_folder_type")
      subject.synced_folder_type = "foo"
      subject.validate(machine)
    end
    it "does warn about deprecation when synced_folder_args is set" do
      expect_deprecation_warning("synced_folder_args")
      subject.synced_folder_args = "foo"
      subject.validate(machine)
    end
    [:nfs, :rsync, :smb, :virtualbox, :type].each do |symbol|
      it "errors if synced_folder_type collides with synced_folder_opts[:#{symbol.to_s}]" do
        expect_deprecation_warning("synced_folder_type")
        subject.synced_folder_opts symbol => symbol.to_s
        subject.synced_folder_type = "foo"
        expect(errors).to include puppet_msg("synced_folder_type_ignored", {synced_folder_type: "foo", type: symbol.to_s})
      end
    end
    it "errors if synced_folder_args is given and type is not rsync" do
      expect_deprecation_warning("synced_folder_args")
      subject.synced_folder_opts :type => "bar"
      subject.synced_folder_args = "foo"
      expect(errors).to include puppet_msg("synced_folder_args_ignored", {args: "foo"})
    end
  end

end
