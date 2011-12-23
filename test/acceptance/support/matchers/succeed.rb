# Matcher that verifies that a process succeeds.
RSpec::Matchers.define :succeed do
  match do |thing|
    thing.exit_code.should == 0
  end

  failure_message_for_should do |actual|
    "expected process to succeed. exit code: #{actual.exit_code}"
  end

  failure_message_for_should_not do |actual|
    "expected process to fail. exit code: #{actual.exit_code}"
  end
end
