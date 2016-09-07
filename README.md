# Partitionable
Short description and motivation.

## Usage
This gem adds support for using the PostgreSQL partitioning mechanism
describe [here](https://www.postgresql.org/docs/9.1/static/ddl-partitioning.html).

It assumes the model you want to partition has `logdate` attribute which will be
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

And the add the `acts_as_partitionable` to the model:

```ruby
class ArticleStat < ApplicationRecord
  acts_as_partitionable
end
```

And that's it. Now you'll have the following methods available for your model:

#### partition_table_name(month, year)

It generates a new for a new partition for that month and year. By default
it uses the model's table name along with the month and the year. Example: `article_stats_y2015m01`

#### create_partition(month, year)

One of the most important methods. It creates a new partition for that month and
year. This partition will inherit from the model's table and will have the
checks to route the requests to the partition.

#### drop_partition(month, year)

Deletes a partition for that month and year. It also deleted all the associated
functions and triggers for that partition.

#### trigger_statement(months_and_years)

It returns the statement that generates all the necessary triggers you need
for inserting data into the partitions for a group of months and years.

Let's say you have the following array of months and years: `[[1, 2015], [2, 2015], [3,2015]]`,
then if you pass that array to the trigger_statement method, it'll return the
statement that generates the triggers for those 3 partitions. You have to make sure
those partitions exist before executing the triggers.
Normally you'll have something like

```ruby
months_and_years.each do |month, year|
  next if self.partition_table_exists?(month, year)
  self.create_partition(month, year)
end
statement = self.trigger_statement(months_and_years)
ActiveRecord::Base.connection.execute(statement)
```
For creating the partitions and then add the triggers.

#### partition_table_exists?(month, year)

Return true if the partition for that month and year exists.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "partitionable", git: "git://github.com/pacuna/partitionable.git"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install partitionable
```

## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
