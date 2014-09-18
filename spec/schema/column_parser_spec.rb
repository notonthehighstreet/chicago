require 'spec_helper'

describe Chicago::Schema::ColumnParser do
  let(:schema) do
    schema = Chicago::StarSchema.new

    schema.define_dimension(:date) do
      columns do
        string :day
      end
    end

    schema.define_dimension(:product) do
      columns do
        string :name
      end
    end

    schema.define_fact(:sales) do
      dimensions :product, :date.as(:order_date), :date.as(:refund_date)
    end

    schema
  end

  subject { described_class.new(schema) }

  it "has a qualified label for roleplayed dimensions" do
    column = subject.parse("sales.order_date.day").first
    expect(column.label).to eql("Day")
    expect(column.qualified_label).to eql("Day (Order Date)")
  end

  it "has a non-qualified label for non-roleplayed dimensions" do
    column = subject.parse("sales.product.name").first

    expect(column.qualified_label).to eql("Name")
  end
end
