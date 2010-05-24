require File.dirname(__FILE__) + "/spec_helper"

describe Chicago::Schema::TypeConverters::DbTypeConverter do
  before :each do 
    @m = Schema::TypeConverters
    @tc = Schema::TypeConverters::DbTypeConverter.new
  end

  it "should return a type converter for MySQL" do
    @mock_db = mock()
    @mock_db.should_receive(:database_type).and_return(:mysql)

    @m::DbTypeConverter.for_db(@mock_db).should be_kind_of(@m::MysqlTypeConverter)
  end

  it "should return a generic type converter for an unknown database" do
    @mock_db = mock()
    @mock_db.should_receive(:database_type).and_return(:foodb)

    @m::DbTypeConverter.for_db(@mock_db).should be_kind_of(@m::DbTypeConverter)
  end

  it "should create an int column if only a maximum is specified" do
    column = ColumnDefinition.new(:name => :id, :type => :integer, :max => 127)
    @tc.db_type(column).should == :integer
  end

  { :smallint  => [-32768, 32767],
    :smallint  => [0, 65535],
  }.each do |expected_db_type, range|

    it "should create a #{expected_db_type} if the maximum column value < #{range.max} and min is >= #{range.min}" do
      column = ColumnDefinition.new(:name => :id, :type => :integer, :max => range.max, :min => range.min)
      @tc.db_type(column).should == expected_db_type
    end
  end

  it "should translate string to :varchar" do
    column = ColumnDefinition.new(:name => :id, :type => :string)
    @tc.db_type(column).should == :varchar
  end

  it "should translate string to :char if column max and min are the same" do
    column = ColumnDefinition.new(:name => :id, :type => :string, :min => 2, :max => 2)
    @tc.db_type(column).should == :char
  end

  it "should return :decimal from #db_type if column type is :money" do
    column = ColumnDefinition.new(:name => :id, :type => :money)
    @tc.db_type(column).should == :decimal
  end
end
