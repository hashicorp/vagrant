require File.expand_path("../../../../base", __FILE__)

describe "VagrantPlugins::Shell::Config" do
  let(:described_class) do
    VagrantPlugins::Shell::Plugin.components.configs[:provisioner][:shell]
  end

  let(:machine)          { double('machine', env: Vagrant::Environment.new) }
  let(:file_that_exists) { File.expand_path(__FILE__)                       }

  subject { described_class.new }

  describe "validate" do
    it "passes with no args" do
      subject.path = file_that_exists
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with string args" do
      subject.path = file_that_exists
      subject.args = "a string"
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with fixnum args" do
      subject.path = file_that_exists
      subject.args = 1
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "passes with array args" do
      subject.path = file_that_exists
      subject.args = ["an", "array"]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "returns an error if args is neither a string nor an array" do
      neither_array_nor_string = Object.new

      subject.path = file_that_exists
      subject.args = neither_array_nor_string
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([
        I18n.t("vagrant.provisioners.shell.args_bad_type")
      ])
    end

    it "handles scalar array args" do
      subject.path = file_that_exists
      subject.args = ["string", 1, 2]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([])
    end

    it "returns an error if args is an array with non-scalar types" do
      subject.path = file_that_exists
      subject.args = [[1]]
      subject.finalize!

      result = subject.validate(machine)

      expect(result["shell provisioner"]).to eq([
        I18n.t("vagrant.provisioners.shell.args_bad_type")
      ])
    end
  end

  describe 'finalize!' do
    it 'changes fixnum args into strings' do
      subject.path = file_that_exists
      subject.args = 1
      subject.finalize!

      expect(subject.args).to eq '1'
    end

    it 'changes fixnum args in arrays into strings' do
      subject.path = file_that_exists
      subject.args = ["string", 1, 2]
      subject.finalize!

      expect(subject.args).to eq ["string", '1', '2']
    end
  end
end
