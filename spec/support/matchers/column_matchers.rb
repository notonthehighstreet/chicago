RSpec::Matchers.define :have_column_named do |name|
  match {|table| table.columns.any? {|c| c.name == name } }

  failure_message_for_should do |table|
    "Expected #{table.class} #{table.name} to have a column named #{name}"
  end

  failure_message_for_should_not do |table|
    "Did not expect #{table.class} #{table.name} to have a column named #{name}"
  end
end
