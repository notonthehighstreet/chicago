Chicago
=======

Chicago is a small-scale data warehouse library written in Ruby.

This library focuses on the following:

* Defining a model that represents a Star Schema.
* Creation of migrations to manipulate one or more concrete database
  schemas to reflect the model.
* Querying data in a Star Schema.

It heavily uses and is influenced by the
[sequel](http://sequel.jeremyevans.net/) library. This library itself provides no ETL functionality; there is a highly unfinished/experimental library for this at [chicago-etl](http://github.com/notonthehighstreet/chicago-etl)

Installation
------------

    gem install chicagowarehouse

Star Schema Features
--------------------

If you are new to star schemas in general, I recommend reading [The
Data Warehouse
Toolkit](http://www.amazon.co.uk/The-Data-Warehouse-Toolkit-Dimensional/dp/0471200247)
by Ralph Kimball & Margy Ross. Briefly though, a star schema is a
sem-denormalised style of database design optimized for
reporting-style queries. In a star schema, there are two types of
tables:

* **Fact tables** store *measures* that can be summed or averaged,
    together with keys to Dimensions.
* **Dimension tables** store denormalised data with which you may want
    to group or filter facts.

Generally speaking, the only links are between 1 fact table and
several dimension tables: facts are not joined to facts, dimensions
are not joined to dimensions - this gives the star schema its name, as
you can see in the picture below:

![Star Schema](/docimages/starschema.png?raw=true)

Not all standard star schema features are implemented yet - probably
the most important ommission is that Type II and Type III dimensions
are not supported (dimensions that retain historic information).

Features that *are* supported include:

* Fact & Type I Dimensions tables
* Measures, additive & semi-additive
* Degenerate Dimensions
* Null Records
* Dimensions with predetermined values
* Key tables for ETL processes, supporting both single integer keys
  and hash keys for dimensions without an original primary key
* Calculated columns

Example Usage
-------------

Defining models:

```ruby
require 'chicago'

SCHEMA = Chicago::StarSchema.new

SCHEMA.define_dimension(:product) do
  columns do
    integer :original_id
    string :name, :default => "Unknown Product"
    money :price
    # ...
  end

  identified_by :name
  natural_key :original_id
  null_record :original_id => 0
end

# ...

SCHEMA.define_fact(:sales) do
  dimensions :product, :customer

  degenerate_dimensions do
    integer :order_id
  end

  measures do
    money :total
    integer :number_of_items
  end
end
```

Contributing
------------

To get specs passing, you'll need to create a test myqsl database, and
copy spec/database.yml.dist to spec/database.yml and populate it
appropriately.
