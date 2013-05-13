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
    # No-op
  end
end
