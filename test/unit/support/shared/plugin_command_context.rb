shared_context 'command plugin helpers' do
  def command_lambda(_name, result, **opts)
    lambda do
      Class.new(Vagrant.plugin('2', 'command')) do
        define_method(:execute) do
          fail opts[:exception] if opts[:exception]
          result
        end
      end
    end
  end
end
