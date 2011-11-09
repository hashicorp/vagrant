RSpec::Matchers.define :have_color do
  match do |actual|
    actual.index("\e[31m")
  end

  failure_message_for_should do |actual|
    "expected output to contain color, but didn't"
  end
end
