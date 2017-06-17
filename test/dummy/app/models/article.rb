class Article < ApplicationRecord
  acts_as_partitionable index_fields: ['slug'], logdate_attr: 'logdate',
                        indices: [
                          {
                            name: 'drafts_by_author',
                            fields: ['author'],
                            where: "published = 'f'"
                          },
                          {
                            fields: %w(slug author),
                            where: "published = 't'"
                          }
                        ]
end
