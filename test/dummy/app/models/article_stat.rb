class ArticleStat < ApplicationRecord
  acts_as_partitionable index_fields: ['site', 'token']
end
