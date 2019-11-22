require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::PackageOutputOverwriteConfirm do
  let(:app) {lambda {|env|}}
  let(:output) {"output.box"}
  let(:env) {{"package.output" => output, ui: double("ui")}}
  let(:message) {"Are you sure you want to overwrite 'output.box'? [y/N] "}

  context "when package output file exist" do
    before do
      allow(File).to receive(:expand_path).with(output, any_args).and_return(output)
      allow(File).to receive(:exist?).with(output).and_return(true)
    end

    %w(y Y).each do |valid|
      it "should set the result to true if '#{valid}' is given" do
        expect(env[:ui]).to receive(:ask).with(message).and_return(valid)
        described_class.new(app, env).call(env)
        expect(env[:result]).to be
      end
    end

    %w(n N).each do |valid|
      it "should set the result to true if '#{valid}' is given" do
        expect(env[:ui]).to receive(:ask).with(message).and_return(valid)
        described_class.new(app, env).call(env)
        expect(env[:result]).to be false
      end
    end
  end

  context "when package output file don't exist" do
    before do
      allow(File).to receive(:expand_path).with(output, any_args).and_return(output)
      allow(File).to receive(:exist?).with(output).and_return(false)
    end

    it "should set the result to true" do
      described_class.new(app, env).call(env)
      expect(env[:result]).to be
    end
  end
end
