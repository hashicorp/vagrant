shared_context "virtualbox" do
  include_context "unit"

  let(:vbox_context) { true                                }
  let(:uuid)         { "1234-abcd-5678-efgh"               }
  let(:vbox_version) { "4.3.4"                             }
  let(:subprocess)   { double("Vagrant::Util::Subprocess") }

  # this is a helper that returns a duck type suitable from a system command
  # execution; allows setting exit_code, stdout, and stderr in stubs.
  def subprocess_result(options={})
    defaults = {exit_code: 0, stdout: "", stderr: ""}
    double("subprocess_result", defaults.merge(options))
  end

  before do
    # we don't want unit tests to ever run commands on the system; so we wire
    # in a double to ensure any unexpected messages raise exceptions
    stub_const("Vagrant::Util::Subprocess", subprocess)

    # drivers will blow up on instantiation if they cannot determine the
    # virtualbox version, so wire this stub in automatically
    allow(subprocess).to receive(:execute).
      with("VBoxManage", "--version", an_instance_of(Hash)).
      and_return(subprocess_result(stdout: vbox_version))

    # drivers also call vm_exists? during init;
    allow(subprocess).to receive(:execute).
      with("VBoxManage", "showvminfo", kind_of(String), kind_of(Hash)).
      and_return(subprocess_result(exit_code: 0))
  end

  around do |example|
    # On Windows, we don't want to accidentally call the actual VirtualBox
    with_temp_env("VBOX_INSTALL_PATH" => nil) do
      example.run
    end
  end
end
