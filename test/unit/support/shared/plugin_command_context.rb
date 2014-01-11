shared_context "command plugin helpers" do
  def command_lambda(name, result)
    lambda do
      Class.new(Vagrant.plugin("2", "command")) do
        define_method(:execute) do
          result
        end
      end
    end
  end
end
