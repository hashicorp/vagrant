# This is a shared example that tests that a command requires a
# Vagrant environment to run properly. The exact command to run
# should be given as a parameter to the shared examples.
shared_examples "a command that requires a Vagrantfile" do |*args|
  let(:command) do
    raise ArgumentError, "A command must be set for the shared example." if args.empty?
    args[0]
  end

  it "fails if no Vagrantfile is found" do
    result = execute(*command)
    result.should_not succeed
    result.stderr.should match_output(:no_vagrantfile)
  end
end

# This is a shared example that tests that the command requires a
# virtual machine to be created, and additionally to be in one of
# many states.
shared_examples "a command that requires a virtual machine" do |*args|
  let(:command) do
    raise ArgumentError, "A command must be set for the shared example." if args.empty?
    args[0]
  end

  it "fails if the virtual machine is not created" do
    assert_execute("vagrant", "init")

    result = execute(*command)
    result.should_not succeed
    result.stderr.should match_output(:error_vm_must_be_created)
  end
end
