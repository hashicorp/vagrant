require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_4_0 do
  include_context "virtualbox"
  let(:vbox_version) { "4.0.0" }
  subject { VagrantPlugins::ProviderVirtualBox::Driver::Meta.new(uuid) }

  it_behaves_like "a version 4.x virtualbox driver"
end
