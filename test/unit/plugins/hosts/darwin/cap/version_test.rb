# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/version"

describe VagrantPlugins::HostDarwin::Cap::Version do
  describe ".version" do
    let(:product_version) { "10.5.1" }
    let(:env) { double(:env) }
    let(:exit_code) { 0 }
    let(:stderr) { "" }
    let(:stdout) { product_version }
    let(:result) {
      Vagrant::Util::Subprocess::Result.new(exit_code, stdout, stderr)
    }

    before do
      allow(Vagrant::Util::Subprocess).to receive(:execute).
        with("sw_vers", "-productVersion").
        and_return(result)
    end

    it "should return a Gem::Version" do
      expect(described_class.version(env)).to be_a(Gem::Version)
    end

    it "should equal the defined version" do
      expect(described_class.version(env)).to eq(Gem::Version.new(product_version))
    end

    context "when version cannot be parsed" do
      let(:product_version) { "invalid"  }

      it "should raise a failure error" do
        expect { described_class.version(env) }.
          to raise_error(Vagrant::Errors::DarwinVersionFailed)
      end
    end

    context "when command execution fails" do
      let(:exit_code) { 1 }

      it "should raise a failure error" do
        expect { described_class.version(env) }.
          to raise_error(Vagrant::Errors::DarwinVersionFailed)
      end
    end
  end
end
