require 'test_helper'

class ActsAsPartitionableTest < ActiveSupport::TestCase
  def test_article_stats_partition_table_name
    assert_equal "article_stats_y2015m01", ArticleStat.partition_table_name(1,2015)
  end
end
