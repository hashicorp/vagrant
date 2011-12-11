require "acceptance/support/output"

# This creates a matcher that is used to match against certain
# Vagrant output. Vagrant output is not what is being tested,
# so all that state is hidden away in Acceptance::Output.
RSpec::Matchers.define :match_output do |expected, *args|
  match do |actual|
    Acceptance::Output.new(actual).send(expected, *args)
  end

  failure_message_for_should do |actual|
    "expected output to match: #{expected} #{args.inspect}"
  end
end
