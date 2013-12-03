shared_context "virtualbox" do
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
    subprocess.stub(:execute).
      with("VBoxManage", "--version", an_instance_of(Hash)).
      and_return(subprocess_result(stdout: vbox_version))

    # drivers also call vm_exists? during init;
    subprocess.stub(:execute).
      with("VBoxManage", "showvminfo", kind_of(String), kind_of(Hash)).
      and_return(subprocess_result(exit_code: 0))
  end
end
