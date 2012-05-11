require 'spec_helper'
require 'chicago/etl'

describe Chicago::ETL::MysqlDumpfileWriter do
  before :each do
    @csv = mock(:csv)
  end
  
  it "outputs specified column values in order" do
    dumpfile = described_class.new(@csv, [:foo, :bar])
    @csv.should_receive(:<<).with(["1", "2"])

    dumpfile << {:foo => "1", :bar => "2", :baz => "not output"}
  end

  it "transforms nil into \\N" do
    dumpfile = described_class.new(@csv, [:foo])
    @csv.should_receive(:<<).with(["\\N"])
    
    dumpfile << {}
  end

  it "outputs 1 for true" do
    dumpfile = described_class.new(@csv, [:foo])
    @csv.should_receive(:<<).with(["1"])
    
    dumpfile << {:foo => true}
  end

  it "outputs 0 for false" do
    dumpfile = described_class.new(@csv, [:foo])
    @csv.should_receive(:<<).with(["0"])
    
    dumpfile << {:foo => false}
  end

  it "will write a row only once with the same id" do
    dumpfile = described_class.new(@csv, [:foo], :id)
    @csv.should_receive(:<<).with(["bar"])
    
    dumpfile << {:id => 1, :foo => "bar"}
    dumpfile << {:id => 1, :foo => "baz"}
  end
end
