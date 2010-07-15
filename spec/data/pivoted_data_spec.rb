require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

describe Chicago::Data::PivotedData do
  before :all do
    @dataset = [{:year => 2009, :month => 1, :value => 1},
                {:year => 2009, :month => 3, :value => 2},
                {:year => 2009, :month => 4, :value => 3},
                {:year => 2010, :month => 1, :value => 4},
                {:year => 2010, :month => 2, :value => 5},
                {:year => 2010, :month => 4, :value => 6}
               ]
  end

  it "should return 2 rows of pivoted data when pivoting on month" do
    rows = Chicago::Data::PivotedData.new(@dataset, :month).map {|row| row }
    rows.should == [{:year => 2009, 1 => 1, 3 => 2, 4 => 3},
                    {:year => 2010, 1 => 4, 2 => 5, 4 => 6}]
  end
end
