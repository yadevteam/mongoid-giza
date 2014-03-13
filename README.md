# Mongoid::Giza [![Build Status](https://travis-ci.org/yadevteam/mongoid-giza.png)](https://travis-ci.org/yadevteam/mongoid-giza) [![Code Climate](https://codeclimate.com/github/yadevteam/mongoid-giza.png)](https://codeclimate.com/github/yadevteam/mongoid-giza) [![Coverage Status](https://coveralls.io/repos/yadevteam/mongoid-giza/badge.png)](https://coveralls.io/r/yadevteam/mongoid-giza) [![Gem Version](https://badge.fury.io/rb/mongoid-giza.png)](http://badge.fury.io/rb/mongoid-giza)

Mongoid layer for the Sphinx fulltext search server that supports block fields and dynamic indexes

## Installation

Add this line to your application's Gemfile:

    gem "mongoid-giza"

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mongoid-giza

## Usage

:warning: **Before proceeding is extremely recommended to read the [Sphinx documentation](http://sphinxsearch.com/docs/current.html) if you are not yet familiar with it. Reading up to chapter 5 is enought to get you going.**

### Configuration file

A YAML configuration file is needed to configure the gem, the Sphinx searchd daemon, optionally the Sphinx indexer and set the default options for the sources and indexes.

The minimum configuration file must have the sphinx.conf output path, the address and port of the searchd daemon, paths to its pid and log files.
It's also a good idea to define a default path for very index.

The `xmlpipe_command` is set to a default when using rails, otherwise you need to set it for each index or a default on the YAML file.
String settings accept ERB, and you have access to the `Mongoid::Giza::Index` from index and source section settings.

The configuration file is automatically loaded when using Rails from `config/giza.yml`, otherwise you will need to call `Mongoid::Giza::Configuration.instance.load` to load it.

**Example:** *(the `xmlpipe_command` used here is already the one used in rails automatically so it's not needed, just for illustration)*

```yaml
development:
  file:
    output_path: "/tmp/sphinx/sphinx.conf"
  searchd:
    address: "localhost"
    port: 9312
    pid_file: "/tmp/sphinx/searchd.pid"
    log: "/tmp/sphinx/searchd.log"
  index:
    path: "/tmp/sphinx"
  source:
    xmlpipe_command: "rails r '<%= index.klass %>.sphinx_indexes[:<%= index.name %>].generate_xmlpipe2(STDOUT)'"
```

### Setting up indexes on models

Use a `sphinx_index` block to create a new index.

The `sphinx_index` method may receive optional settings that will be set in this index's section or in its source section on the generated sphinx configuration file.
These settings take precedence to the defaults defined in the configuration file.

A model may have more than one index, but they need to have different names.
If two or more indexes have the same name the last one to be defined is the one which will exist.

An index name is the name of the class it's defined on unless overwritten by the `name` method inside the index definition block.

Besides `name`, `field`, `attribute` and `criteria` are the methods avaible inside the index definition block.

Both `field` and `attribute` take a name as first parameter that may match with a Mongoid field. In this case the value of the field will be used when indexing the objects.
The `attribute` method may receive a second paramenter that defines the type of the attribute. If it is ommited, than the type of the Mongoid field will be used.

At last, both methods may take an block with the object as parameter. The return of the block will be used as the value of the field or attribute when indexing.

The `criteria` method receives a `Mongoid::Criteria` that will be used to select the objects that will be indexed.
It's `Class.all` by default.

**Example:** Creating a index on the person model

```ruby
class Person
  include Mongoid::Document
  include Mongoid::Giza

  field :name
  field :age, type: Integer

  sphinx_index(enable_star: 1) do
    field :name
    field :bio do |person|
      "#{person.name.capitalize} was born #{person.age.years.days} ago"
    end
    attribute :age
  end
end
```

#### Dynamic Indexes

Because of the schemaless nature of MongoDB, sometimes you may find problems mapping your mongo models to sphinx indexes.
To circunvent this limitation Mongoid::Giza supports dynamic indexes.

When you define a dynamic index, it will generate a regular index based on your definition for each object of the class.
This allows the creation of different indexes for objects of the same model that have different dynamic fields.

Although it's not necessary, dynamic indexes are better used together with a `criteria`,
so it's possible to control which objects of the class will be indexed on each determined index.

To create a dynamic index all that needs to be done is pass the object to the `sphin_index` block.

**Example:** Creating a dynamic index on the person model.
This dynamic index will generate one index for each job that is associated to a person.
On each index only the people that have that job will be indexed.
Finally each dynamic attribute of the job will be a field on its index.

```ruby
class Job
  include Mongoid::Document

  field :name
  # each job object has specific dynamic fields

  has_many :people
end

class Person
  include Mongoid::Document
  include Mongoid::Giza

  field :name
  field :age, type: Integer

  belongs_to :job

  sphinx_index do |person|
    name person.job.name
    criteria Person.where(job: person.job)
    person.job.attributes.except("name").each do |attr, val|
      field attr.to_sym
    end
  end
end
```

### Indexing

There are 3 ways to populate the Sphinx index: use the model class' `sphinx_indexer!` method, `Mongoid::Giza::Indexer.instance.index!` or `Mongoid::Giza::Indexer.instance.full_index!`

* **sphinx_indexer!:** Will execute the indexer program only on the indexes of the class.
Does not regenerate dynamic indexes.
* **index!:** Will execute the indexer.
Does not regenerate dynamic indexes.
* **full_index!:** Will regenerate dynamic indexes, render the configuration file and execute the indexer program on all indexes.

This gem does not execute none of those automatically to let the you define what is the best reindexing strategy for your software.

### Searching

Use the `search` block on the class that have the indexes where the search should run.
It returns a result array, where each position of the array is a [riddle result hash](http://rdoc.info/github/pat/riddle/Riddle/Client#query-instance_method), plus a key with the class name, that has the `Mongoid::Criteria` that selects the matching objects from the mongo database.

Inside the `search` block use the `fulltext` method to perform a fulltext search.
If multiple `fulltext` are called inside a `search` block, then each one will generate a separated query and will return a new position o the results array.

To filter your search using the attributes defined on the index creation, use the `with` and `without` methods, that accept the name of the attribute and the value or range.

To order the results, use the `order_by` method, that receives the *attribute* used for sorting and a Symbol, that can be either `:asc` or `:desc`.

Every other [Riddle::Client](http://rdoc.info/github/pat/riddle/Riddle/Client) setter is avaible without the **=**, to maintain the DSL syntax consistent.

**Example:** Searching on the person class

```ruby
results = Person.search do
  fulltext "john"
  with :age 18..40
  order_by :age :asc
end

results.first[:Person].each do |person|
 puts "#{person.name} is #{person.age} years old"
end
```

## TODO

* Support delta indexing
* Support RT indexes
* Support distributed indexes

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
