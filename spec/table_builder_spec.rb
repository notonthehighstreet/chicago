require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::TableBuilder do
  before :each do
    @mock_db = mock(:db)
    @builder = Schema::TableBuilder.new(@mock_db)
  end
end
