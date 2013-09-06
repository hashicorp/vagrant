describe Vagrant::CLI do
  describe "parsing options" do
    let(:klass) do
      Class.new(described_class)
    end

    let(:environment) do
      ui = double("UI::Silent")
      ui.stub(:info => "bar")
      env = double("Vagrant::Environment")
      env.stub(:active_machines => [])
      env.stub(:ui => ui)
      env.stub(:root_path => "foo")
      env.stub(:machine_names => [])
      env
    end

    it "returns a non-zero exit status if an invalid command is given" do
      result = klass.new(["destroypp"], environment).execute
      result.should_not == 0
    end

    it "returns an exit status of zero if a valid command is given" do
      result = klass.new(["destroy"], environment).execute
      result.should == 0
    end
  end
end
