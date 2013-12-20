require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::SyncedFolders do
  include_context "synced folder actions"

  let(:app) { lambda { |env| } }
  let(:env) { { :machine => machine, :ui => ui } }
  let(:machine) do
    double("machine").tap do |machine|
      machine.stub(:config).and_return(machine_config)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      top_config.stub(:vm => vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:ui) do
    double("ui").tap do |result|
      result.stub(:info)
      result.stub(:warn)
    end
  end

  subject { described_class.new(app, env) }

  describe "call" do
    let(:synced_folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      env[:root_path] = Pathname.new(Dir.mktmpdir)
      subject.stub(:plugins => plugins)
      subject.stub(:synced_folders => synced_folders)
    end

    it "should warn if a guest paths shadows an earlier entry" do
      synced_folders["default"] = {
        "foo" => {
          hostpath: "foo",
          guestpath: "/vagrant/foo",
        },

        "root" => {
          hostpath: "bar",
          guestpath: "/vagrant",
        }

      }

      expect(env[:ui]).to receive(:warn) do |msg|
        expect(msg).to match(/shadows/)
      end

      subject.call(env)
    end

    it "shouldn't warn if a guest paths is subdirectory of an earlier entry" do
      synced_folders["default"] = {
        "foo" => {
          hostpath: "foo",
          guestpath: "/vagrant",
        },

        "root" => {
          hostpath: "bar",
          guestpath: "/vagrant/bar",
        }

      }

      expect(env[:ui]).to_not receive(:warn)
      subject.call(env)
    end

    it "should create on the host if specified" do
      synced_folders["default"] = {
        "root" => {
          hostpath: "foo",
          guestpath: "/foo",
        },

        "other" => {
          hostpath: "bar",
          guestpath: "/bar",
          create: true,
        }
      }

      subject.call(env)

      env[:root_path].join("foo").should_not be_directory
      env[:root_path].join("bar").should be_directory
    end

    it "should invoke prepare then enable" do
      order = []
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          order << :prepare
        end

        define_method(:enable) do |machine, folders, opts|
          order << :enable
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
          guestpath: "/foo",
        },

        "other" => {
          hostpath: "bar",
          guestpath: "/bar",
          create: true,
        }
      }

      subject.call(env)

      order.should == [:prepare, :enable]
    end

    it "should scope hash override the settings" do
      actual = nil
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          actual = folders
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
          guestpath: "/foo",
          tracker__foo: "bar",
        },
      }

      subject.call(env)

      actual["root"][:foo].should == "bar"
    end
  end
end
