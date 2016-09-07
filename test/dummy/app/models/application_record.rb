class ApplicationRecord < ActiveRecord::Base
  include Partitionable::ActsAsPartitionable

  self.abstract_class = true
end
