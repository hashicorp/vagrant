# This tests that VM is up as a linked clone
shared_examples 'provider/linked_clone' do |provider, options|
  if !options[:box]
    raise ArgumentError,
      "box option must be specified for provider: #{provider}"
  end

  include_context 'acceptance'

  before do
    environment.skeleton('linked_clone')
    assert_execute('vagrant', 'box', 'add', 'box', options[:box])
  end

  after do
    assert_execute('vagrant', 'destroy', '--force')
  end

  it 'creates machine as linked clone' do
    status('Test: machine is created successfully')
    result = execute('vagrant', 'up', "--provider=#{provider}")
    expect(result).to exit_with(0)

    status('Test: master VM is created')
    expect(result.stdout).to match(/master VM/)

    status('Test: machine is a master VM clone')
    expect(result.stdout).to match(/Cloning/)

    status('Test: machine is available by ssh')
    result = execute('vagrant', 'ssh', '-c', 'echo foo')
    expect(result).to exit_with(0)
    expect(result.stdout).to match(/foo\n$/)
  end
end
