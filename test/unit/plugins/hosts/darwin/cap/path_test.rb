require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/path"

describe VagrantPlugins::HostDarwin::Cap::Path do
  describe ".resolve_host_path" do
    let(:env) { double("environment") }
    let(:path) { "/test/vagrant/path" }
    let(:firmlink_map) { {} }

    before { allow(described_class).to receive(:firmlink_map).and_return(firmlink_map) }

    it "should not change the path when no firmlinks are defined" do
      expect(described_class.resolve_host_path(env, path)).to eq(path)
    end

    context "when firmlink map contains non-matching values" do
      let(:firmlink_map) { {"/users" => "users", "/system" => "system"} }

      it "should not change the path" do
        expect(described_class.resolve_host_path(env, path)).to eq(path)
      end
    end

    context "when firmlink map contains matching value" do
      let(:firmlink_map) { {"/users" => "users", "/test" => "test"} }

      it "should update the path" do
        expect(described_class.resolve_host_path(env, path)).not_to eq(path)
      end

      it "should prefix the path with the defined data path" do
        expect(described_class.resolve_host_path(env, path)).to start_with(described_class.const_get(:FIRMLINK_DATA_PATH))
      end
    end

    context "when firmlink map match points to different named target" do
      let(:firmlink_map) { {"/users" => "users", "/test" => "other"} }

      it "should update the path" do
        expect(described_class.resolve_host_path(env, path)).not_to eq(path)
      end

      it "should prefix the path with the defined data path" do
        expect(described_class.resolve_host_path(env, path)).to start_with(described_class.const_get(:FIRMLINK_DATA_PATH))
      end

      it "should include the updated path name" do
        expect(described_class.resolve_host_path(env, path)).to include("other")
      end
    end
  end

  describe ".firmlink_map" do
    before { described_class.reset! }

    context "when firmlink definition file does not exist" do
      before { expect(File).to receive(:exist?).with(described_class.const_get(:FIRMLINK_DEFS)).and_return(false) }

      it "should return an empty hash" do
        expect(described_class.firmlink_map).to eq({})
      end
    end

    context "when firmlink definition file exists with values" do
      before do
        expect(File).to receive(:exist?).with(described_class.const_get(:FIRMLINK_DEFS)).and_return(true)
        expect(File).to receive(:readlines).with.(described_class.const_get(:FIRMLINK_DEFS)).
          and_return(["/System\tSystem\n", "/Users\tUsers\n", "/Library/Something\tLibrary/Somethingelse"])

        it "should generate a non-empty hash" do
          expect(described_class.firmlink_map).not_to be_empty
        end

        it "should properly create entries" do
          result = described_class.firmlink_map
          expect(result["/System"]).to eq("System")
          expect(result["/Users"]).to eq("Users")
          expect(result["/Library/Something"]).to eq("Library/Somethingelse")
        end

        it "should only load values once" do
          result = describe_class.firmlink_app
          expect(File).not_to receive(:readlines)
          result = describe_class.firmlink_app
        end
      end
    end
  end
end
