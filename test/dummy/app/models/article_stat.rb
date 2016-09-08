class ArticleStat < ApplicationRecord
  acts_as_partitionable index_fields: ['site', 'token'], logdate_attr: 'logdate'
end
