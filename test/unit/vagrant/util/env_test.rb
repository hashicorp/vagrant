require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/env'

describe Vagrant::Util::Env do
  context "with valid environment variables" do
    before do
      ENV["VAGRANT_TEST"] = "1"
    end

    after do
      ENV.delete("VAGRANT_TEST")
    end

    it "should execute block with original environment variables" do
      Vagrant::Util::Env.with_original_env do
        expect(ENV["VAGRANT_TEST"]).to be_nil
      end
    end

    it "should replace environment variables after executing block" do
      Vagrant::Util::Env.with_original_env do
        expect(ENV["VAGRANT_TEST"]).to be_nil
      end
      expect(ENV["VAGRANT_TEST"]).to eq("1")
    end
  end

  context "with invalid environment variables" do
    it "should not attempt to restore invalid environment variable" do
      invalid_vars = ENV.to_hash.merge("VAGRANT_OLD_ENV_" => "INVALID")
      mock = expect(ENV).to receive(:each)
      invalid_vars.each do |k,v|
        mock.and_yield(k, v)
      end
      expect do
        Vagrant::Util::Env.with_original_env do
          expect(ENV["VAGRANT_TEST"]).to be_nil
        end
      end.not_to raise_error
    end
  end
end
