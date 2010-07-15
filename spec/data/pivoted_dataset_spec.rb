require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Chicago::Data::PivotedDataset do
  before :each do
    @dataset = [{:year => 2009, :month => 1, :value => 1},
                {:year => 2009, :month => 3, :value => 2},
                {:year => 2009, :month => 4, :value => 3},
                {:year => 2010, :month => 1, :value => 4},
                {:year => 2010, :month => 2, :value => 5},
                {:year => 2010, :month => 4, :value => 6}
               ]

    # Stub Sequel::Dataset methods
    class << @dataset
      def all
        self
      end

      def columns
        [:year, :month, :value]
      end
    end
  end

  it "should return 2 rows of pivoted data when pivoting on month" do
    rows = Chicago::Data::PivotedDataset.new(@dataset, :month).to_a
    rows.should == [{:year => 2009, 1 => 1, 3 => 2, 4 => 3},
                    {:year => 2010, 1 => 4, 2 => 5, 4 => 6}]
  end

  it "should return 1 row of pivoted data when pivoting on year and month" do
    rows = Chicago::Data::PivotedDataset.new(@dataset, [:year, :month]).map {|row| row }
    rows.should == [{ 2009 => {1 => 1, 3 => 2, 4 => 3},
                      2010 => {1 => 4, 2 => 5, 4 => 6}
                    }]
  end

  it "should return the pivot column headings" do
    Chicago::Data::PivotedDataset.new(@dataset, :month).pivot_columns.sort.should == [1,2,3,4]
  end

  it "should return nested pivot column headings" do
    Chicago::Data::PivotedDataset.new(@dataset, [:year, :month]).pivot_columns.should == \
      [[2009, 2010], [1,3,4,2]]
  end

  it "should return the other column headings" do
    Chicago::Data::PivotedDataset.new(@dataset, :month).other_columns.should == [:year]
  end

  it "should allow the value key to be changed" do
    dataset = [{:year => 2009, :month => 1, :v => 1},
               {:year => 2010, :month => 4, :v => 6}]
    
    rows = Chicago::Data::PivotedDataset.new(dataset, :month, :value_key => :v, :cache_sql_result => false).to_a
    rows.should == [{:year => 2009, 1 => 1},
                    {:year => 2010, 4 => 6}]
  end
end
