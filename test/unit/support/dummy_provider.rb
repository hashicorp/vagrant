module VagrantTests
  class DummyProviderPlugin < Vagrant.plugin("2")
    name "Dummy Provider"
    description <<-EOF
    This creates a provider named "dummy" which does nothing, so that
    the unit tests aren't reliant on VirtualBox (or any other real
    provider for that matter).
    EOF

    provider(:dummy) { DummyProvider }
  end

  class DummyProvider < Vagrant.plugin("2", :provider)
    def initialize(machine)
      @machine = machine
    end

    def state=(id)
      state_file.open("w+") do |f|
        f.write(id.to_s)
      end
    end

    def state
      if !state_file.file?
        new_state = @machine.id
        new_state = Vagrant::MachineState::NOT_CREATED_ID if !new_state
        self.state = new_state
      end

      state_id = state_file.read.to_sym
      Vagrant::MachineState.new(state_id, state_id.to_s, state_id.to_s)
    end

    protected

    def state_file
      @machine.data_dir.join("dummy_state")
    end
  end
end
