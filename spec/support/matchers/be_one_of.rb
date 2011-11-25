RSpec::Matchers.define :be_one_of do |possibilities|
  match {|arg| possibilities.any? {|p| p == arg } }

  failure_message_for_should do |arg|
    "Expected #{arg.inspect} to be one of #{possibilities.inspect}"
  end

  failure_message_for_should_not do |arg|
    "Did not expect #{arg.inspect} to be one of #{possibilities.inspect}"
  end
end
