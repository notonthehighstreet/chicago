require "spec_helper"

describe Chicago::ETL::DatabaseSource do
  it "should have a name" do
    ETL::DatabaseSource.define('users').name.should == :users
  end

  it "should have a table name for the table in the staging area" do
    ETL::DatabaseSource.define(:users).staging_table_name.should == :original_users
  end

  it "should have a table name for the table in the source database" do
    ETL::DatabaseSource.define(:users).source_table_name.should == :users
  end

  it "should have a mutable source table name" do
    ETL::DatabaseSource.define(:users) do
      self.source_table_name = :foo_bar
    end.source_table_name.should == :foo_bar
  end

  it "should define the columns to be extracted" do
    ETL::DatabaseSource.define(:users) do
      columns :id, :name, :email
    end.column_names.should == [:id, :name, :email]
  end
end
