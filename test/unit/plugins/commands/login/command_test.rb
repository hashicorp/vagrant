require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/login/command")

describe VagrantPlugins::LoginCommand::Command do
  include_context "unit"

  let(:env) { isolated_environment.create_vagrant_env }

  let(:token_path) { env.data_dir.join("vagrant_login_token") }

  let(:stdout) { StringIO.new }
  let(:stderr) { StringIO.new }

  subject { described_class.new(argv, env) }

  before do
    stub_env("ATLAS_TOKEN" => "")
  end

  describe "#execute" do
    context "with no args" do
      let(:argv) { [] }
    end

    context "with --check" do
      let(:argv) { ["--check"] }

      context "when there is a token" do
        before do
          stub_request(:get, %r{^#{Vagrant.server_url}/api/v1/authenticate})
            .to_return(status: 200)
        end

        before do
          File.open(token_path, "w+") { |f| f.write("abcd1234") }
        end

        it "returns 0" do
          expect(subject.execute).to eq(0)
        end
      end

      context "when there is no token" do
        it "returns 1" do
          expect(subject.execute).to eq(1)
        end
      end
    end

    context "with --logout" do
      let(:argv) { ["--logout"] }

      it "returns 0" do
        expect(subject.execute).to eq(0)
      end

      it "clears the token" do
        subject.execute
        expect(File.exist?(token_path)).to be(false)
      end
    end

    context "with --token" do
      let(:argv) { ["--token", "efgh5678"] }

      context "when the token is valid" do
        before do
          stub_request(:get, %r{^#{Vagrant.server_url}/api/v1/authenticate})
            .to_return(status: 200)
        end

        it "sets the token" do
          subject.execute
          token = File.read(token_path).strip
          expect(token).to eq("efgh5678")
        end

        it "returns 0" do
          expect(subject.execute).to eq(0)
        end
      end

      context "when the token is invalid" do
        before do
          stub_request(:get, %r{^#{Vagrant.server_url}/api/v1/authenticate})
            .to_return(status: 401)
        end

        it "returns 1" do
          expect(subject.execute).to eq(1)
        end
      end
    end
  end
end
