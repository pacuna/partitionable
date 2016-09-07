# Partitionable

This gem adds support for using the PostgreSQL partitioning mechanism
describe [here](https://www.postgresql.org/docs/9.1/static/ddl-partitioning.html).

## Usage

Partitionable assumes the model you want to partition has a `logdate` attribute which will be
used for checking the partitions constraints and triggers.

### Example

Let's say you have a model named `ArticleStat` and its respective table named `article_stats`.

First, add the module to `app/models/application_record.rb`:

```ruby
class ApplicationRecord < ActiveRecord::Base

  include Partitionable::ActsAsPartitionable
  self.abstract_class = true
end
```

And then add the `acts_as_partitionable` method to the model. The index fields is a mandatory
options. It'll add an index for those attributes when creating the partitions:

```ruby
class ArticleStat < ApplicationRecord
  acts_as_partitionable, index_fields: ['id', 'site']
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

## TODO

- Custom logdate attribute passed in the options hash

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
