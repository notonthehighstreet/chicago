require 'spec_helper'
require 'chicago/etl/key_builder'

describe Chicago::ETL::KeyBuilder do
  before :all do
    @schema = Chicago::StarSchema.new
    @schema.define_dimension(:user) do
      columns { integer :original_id }
    end

    @schema.define_dimension(:address) do
      columns do
        string :line1
        string :post_code
      end

      natural_key :line1, :post_code
    end

    @schema.define_dimension(:random) do
      columns do
        string :foo
      end
    end
  end
  
  before :each do
    @db = stub(:staging_database).as_null_object
    @db.stub(:[]).and_return(stub(:max => nil, :select_hash => {}))
  end

  describe "for identifiable dimensions" do
    before :each do
      @dimension = @schema.dimension(:user)
    end

    it "returns an incrementing key, given a row" do
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 2).should == 1
      builder.key(:original_id => 3).should == 2
    end

    it "returns the same key for the same record" do
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 2).should == 1
      builder.key(:original_id => 2).should == 1
    end

    it "updates keys in a thread-safe fashion" do
      builder = described_class.for_dimension(@dimension, @db)
      builder.stub(:flush)
      # These seem to need to be a fairly large number of times to see
      # errors
      t1 = Thread.new { 100000.times {|i| builder.key({:original_id => i}) } }
      t2 = Thread.new { 100000.times {|i| builder.key({:original_id => i + 100_000}) } }
      t1.join
      t2.join
      builder.key(:original_id => 200_003).should == 200001
    end

    it "takes into account the current maximum key in the database" do
      @db.stub(:[]).with(:keys_dimension_user).and_return(stub(:max => 2, :select_hash => {}))
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 1).should == 3
    end

    it "returns previously created keys" do
      dataset = stub(:dataset, :max => 1, :select_hash => {40 => 1})
      @db.stub(:[]).with(:keys_dimension_user).and_return(dataset)

      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 30).should == 2
      builder.key(:original_id => 40).should == 1
    end

    it "raises an error when original_id isn't present in the row" do
      builder = described_class.for_dimension(@dimension, @db)
      expect { builder.key(:foo => :bar) }.to raise_error(Chicago::ETL::KeyError)
    end

    it "flushes new keys to a key table" do
      dataset = stub(:dataset, :max => 1, :select_hash => {40 => 1})
      dataset.stub(:insert_replace => dataset)
      @db.stub(:[]).with(:keys_dimension_user).and_return(dataset)

      dataset.should_receive(:multi_insert).
        with([{:original_id => 30, :dimension_id => 2}])
                                              
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 30)
      builder.key(:original_id => 40)
      builder.flush
    end

    it "flushes new keys only once" do
      dataset = stub(:dataset, :max => 1, :select_hash => {40 => 1})
      dataset.stub(:insert_replace => dataset)
      @db.stub(:[]).with(:keys_dimension_user).and_return(dataset)

      dataset.should_receive(:multi_insert).
        with([{:original_id => 30, :dimension_id => 2}])
      dataset.should_receive(:multi_insert).with([])
                                              
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:original_id => 30)
      builder.key(:original_id => 40)
      builder.flush
      builder.flush
    end

    it "replaces old mappings with new values" do
      dataset = stub(:dataset, :max => 1, :select_hash => {40 => 1}, :multi_insert => nil)
      @db.stub(:[]).with(:keys_dimension_user).and_return(dataset)

      dataset.should_receive(:insert_replace).and_return(dataset)
      described_class.for_dimension(@dimension, @db).flush
    end
  end

  describe "for non-identifiable dimensions with natural keys" do
    before :each do
      @dimension = @schema.dimension(:address)
    end

    it "returns an incrementing key, given a row" do
      builder = described_class.for_dimension(@dimension, @db)
      builder.key(:line1 => "some street", :post_code => "TW3 X45").should == 1
      builder.key(:line1 => "some road", :post_code => "TW3 X45").should == 2
    end

    it "inserts the hash as a binary literal" do
      builder = described_class.for_dimension(@dimension, @db)
      # Yuck. Don't like the implementation test, but mock
      # expectations fail here for some reason, maybe because of the
      # Sequel::LiteralString?
      builder.key_for_insert(builder.original_key(:line1 => "some street", :post_code => "TW3 X45")).should == "0x817860F2417EB83D81FEA9D82E6B213A".lit
    end

    it "selects the Hex version of the binary column for the cache" do
      dataset = stub(:dataset, :max => 1).as_null_object
      @db.stub(:[]).with(:keys_dimension_address).and_return(dataset)

      dataset.should_receive(:select_hash).with(:hex.sql_function(:original_id).as(:original_id), :dimension_id).and_return({})
      
      described_class.for_dimension(@dimension, @db).key(:line1 => "foo")
    end

    it "uses all columns as the natural key if one isn't defined" do
      @dimension = @schema.dimension(:random)
      described_class.
        for_dimension(@dimension, @db).
        original_key(:foo => "bar").
        should == "3D75EEC709B70A350E143492192A1736"
    end
  end
end
