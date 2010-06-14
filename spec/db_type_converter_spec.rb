require File.dirname(__FILE__) + "/spec_helper"

shared_examples_for "All DB type converters" do
  context "#db_type" do
    it "should return :varchar for a string column" do
      column = ColumnDefinition.new(:name => :id, :type => :string)
      @tc.db_type(column).should == :varchar
    end

    it "should return :char for a string column that has equal max and min attributes" do
      column = ColumnDefinition.new(:name => :id, :type => :string, :min => 2, :max => 2)
      @tc.db_type(column).should == :char
    end

    it "should return :integer for an column with a max but no min attribute set" do
      column = ColumnDefinition.new(:name => :id, :type => :integer, :max => 127)
      @tc.db_type(column).should == :integer
    end

    it "should return :decimal for a money column type" do
      column = ColumnDefinition.new(:name => :id, :type => :money)
      @tc.db_type(column).should == :decimal
    end
  end
end

describe "DbTypeConverter.for_db" do
  before :each do
    @mock_db = mock()
  end

  it "should return a type converter specific to MySQL if the database type is :mysql" do
    @mock_db.should_receive(:database_type).and_return(:mysql)

    converter = Schema::TypeConverters::DbTypeConverter.for_db(@mock_db)
    converter.should be_kind_of(Schema::TypeConverters::MysqlTypeConverter)
  end

  it "should return a generic type converter for an unknown database type" do
    @mock_db.should_receive(:database_type).and_return(:foodb)

    converter = Schema::TypeConverters::DbTypeConverter.for_db(@mock_db)
    converter.should be_kind_of(Schema::TypeConverters::DbTypeConverter)
  end
end

describe "Generic DbTypeConverter" do
  it_should_behave_like "All DB type converters"

  before :each do 
    @tc = Schema::TypeConverters::DbTypeConverter.new
  end

  { :smallint  => [-32768, 32767],
    :smallint  => [0, 65535],
  }.each do |expected_db_type, range|

    it "should create a #{expected_db_type} if the maximum column value < #{range.max} and min is >= #{range.min}" do
      column = ColumnDefinition.new(:name => :id, :type => :integer, :max => range.max, :min => range.min)
      @tc.db_type(column).should == expected_db_type
    end
  end
end

describe Chicago::Schema::TypeConverters::MysqlTypeConverter do
  it_should_behave_like "All DB type converters"

  before :each do
    @tc = Schema::TypeConverters::MysqlTypeConverter.new
  end

  context "#db_type" do
    { :tinyint   => [-127, 128],
      :tinyint   => [0, 255],
      :smallint  => [-32768, 32767],
      :smallint  => [0, 65535],
      :mediumint => [-8388608, 8388607],
      :mediumint => [0, 16777215],
      :integer   => [-2147483648, 2147483647],
      :integer   => [0, 4294967295],
      :bigint    => [-9223372036854775808, 9223372036854775807],
      :bigint    => [0, 18446744073709551615]

    }.each do |expected_db_type, range|
      
      it "should return #{expected_db_type} if the maximum column value < #{range.max} and min is >= #{range.min}" do
        column = ColumnDefinition.new(:name => :id, :type => :integer, :max => range.max, :min => range.min)
        @tc.db_type(column).should == expected_db_type
      end
    end

    it "should raise an ArgumentError if either of the min/max values are out of bounds" do
      column = ColumnDefinition.new(:name => :id, 
                                    :type => :integer, 
                                    :min => 0, 
                                    :max => 18_446_744_073_709_551_616)
      
      lambda { @tc.db_type(column) }.should raise_error(ArgumentError)
    end

    it "should return :enum if the column definition has elements" do
      column = ColumnDefinition.new(:name => :id, :type => :string, :elements => ["A", "B"])
      @tc.db_type(column).should == :enum
    end

    it "should return :varchar if the column definition has a large number of elements" do
      column = ColumnDefinition.new(:name => :id, :type => :string, :elements => stub(:size => 70_000))
      @tc.db_type(column).should == :varchar
    end
  end
end
