shared_context "command plugin helpers" do
  def command_lambda(name, result, **opts)
    lambda do
      Class.new(Vagrant.plugin("2", "command")) do
        define_method(:execute) do
          raise opts[:exception] if opts[:exception]
          result
        end
      end
    end
  end
end
