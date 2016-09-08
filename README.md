[![Build Status](https://travis-ci.org/pacuna/partitionable.svg?branch=master)](https://travis-ci.org/pacuna/partitionable)
# Partitionable

This gem adds support for using the PostgreSQL partitioning mechanism
describe [here](https://www.postgresql.org/docs/9.1/static/ddl-partitioning.html).

## Usage

Partitionable assumes the model you want to partition has a date attribute which will be
used for checking the partitions constraints and triggers.

### Example

Let's say you have a model named `ArticleStat` and its respective table named `article_stats`.
Suppose this model also has a `logdate` attribute of type date. We want to partition
the data by year and month using this attribute.

First, add the module to `app/models/application_record.rb`:

```ruby
class ApplicationRecord < ActiveRecord::Base

  include Partitionable::ActsAsPartitionable
  self.abstract_class = true
end
```

And then add the `acts_as_partitionable` method to the model. The `index_fields` and `logdate_attr` are mandatory
options. The first one adds an index for those attributes when creating the partitions and the latter
is the date attribute used for routing the records to the correct partitions:

```ruby
class ArticleStat < ApplicationRecord
  acts_as_partitionable index_fields: ['id', 'site'], logdate_attr: 'logdate'
end
```

And that's it. Now every time you create a new record, the gem will create
the correspondent partition table if doesn't exists. It also will update the trigger
function so every other new record that should go into this partition gets correctly
routed.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "partitionable", git: "git://github.com/pacuna/partitionable.git"
```

And then execute:
```bash
$ bundle
```

## Tests

First, create the database for the dummy embedded application:

```bash
cd test/dummy
bin/rails db:setup
cd ../..
```
Then you can run the tests with:

```bash
bin/test
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
