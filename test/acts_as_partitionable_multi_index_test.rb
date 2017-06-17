require 'test_helper'

class ActsAsPartitionableMultiIndexTest < ActiveSupport::TestCase
  def test_articles_partition_name
    assert_equal 'articles_y2017m01', Article.partition_name(1, 2017)
  end

  def test_articles_create_partition
    Article.create_partition(1, 2017)
    assert_equal true, ActiveRecord::Base.connection.data_source_exists?('articles_y2017m01')
  end

  def test_articles_partition_exists?
    Article.create_partition(1, 2011)
    assert_equal true, Article.partition_exists?(1, 2011)
  end

  def test_articles_drop_partition_table
    Article.create_partition(2, 2014)
    Article.drop_partition(2, 2014)
    assert_equal false, ActiveRecord::Base.connection.data_source_exists?('articles_y2014m02')
  end

  def test_articles_create_table_statement
    statement = <<-SQL
          CREATE TABLE articles_y2014m02 (
              CHECK ( logdate >= DATE '2014-02-01' AND logdate < DATE '2014-03-01' )
          ) INHERITS (articles);
          CREATE INDEX articles_y2014m02_slug ON articles_y2014m02 (slug);
CREATE INDEX articles_y2014m02_drafts_by_author ON articles_y2014m02 (author) WHERE published = 'f';
CREATE INDEX articles_y2014m02_slug_author ON articles_y2014m02 (slug,author) WHERE published = 't';
            SQL
    assert_equal statement, Article.create_table_statement(2, 2014)
  end

  def test_articles_get_updated_trigger_statement
    Article.create_partition(1, 2000)
    Article.create_partition(2, 2000)
    Article.create_partition(3, 2000)

    statement = Article.trigger_statement [[1, 2000], [2, 2000], [3, 2000]]
    assert_equal statement, Article.updated_trigger_statement
  end
end
