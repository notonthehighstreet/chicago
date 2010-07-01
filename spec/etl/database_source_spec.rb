require File.dirname(__FILE__) + "/../spec_helper"

describe Chicago::ETL::DatabaseSource do
  it "should have a name" do
    ETL::DatabaseSource.define('users').name.should == :users
  end

  it "should have a table name for the table in the staging area" do
    ETL::DatabaseSource.define(:users).table_name.should == :original_users
  end

  it "should have a mutable table name" do
    ETL::DatabaseSource.define(:users) do
      self.table_name = :foo_bar
    end.table_name.should == :foo_bar
  end

  it "should define the columns to be extracted" do
    ETL::DatabaseSource.define(:users) do
      columns :id, :name, :email
    end.column_names.should == [:id, :name, :email]
  end
end
