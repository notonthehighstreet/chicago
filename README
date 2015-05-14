Chicago
=======

Chicago is a small-scale data warehouse library written in Ruby.

This library focuses on the following:

* Defining a model that represents a Star Schema.
* Creation of migrations to manipulate one or more concrete database
  schemas to reflect the model.
* Querying data in a Star Schema.

It heavily uses and is influenced by the
[sequel](http://sequel.jeremyevans.net/) library.

Star Schema Features Supported
------------------------------

If you are new to star schemas in general, I recommend reading [The
Data Warehouse
Toolkit](http://www.amazon.co.uk/The-Data-Warehouse-Toolkit-Dimensional/dp/0471200247)
by Ralph Kimball & Margy Ross. Briefly though, a star schema is a
sem-denormalised style of database design optimized for
reporting-style queries. In a star schema, there are two types of
tables:

* **Fact tables** store *measures* that can be summed or averaged,
    together with keys to Dimensions.
* **Dimension tables** which store denormalised data with which you
    may want to group or filter facts.

Generally speaking, the only links are between 1 fact table and
several dimension tables: facts are not joined to facts, dimensions
are not joined to dimensions - this gives the star schema its name, as
you can see in the picture below:

![Star Schema](/docimages/starschema.png?raw=true)

Contributing
============

To get specs passing, you'll need to create a test myqsl database, and
copy spec/database.yml.dist to spec/database.yml and populate it
appropriately.
