require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::ETL::TableSource do
  it "should have a name" do
    ETL::TableSource.define('users').name.should == :users
  end

  it "should have a table name for the table in the staging area" do
    ETL::TableSource.define(:users).table_name.should == :original_users
  end

  it "should define the columns to be extracted" do
    ETL::TableSource.define(:users) do
      columns :id, :name, :email
    end.column_names.should == [:id, :name, :email]
  end
end