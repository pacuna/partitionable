require 'test_helper'

class ActsAsPartitionableTest < ActiveSupport::TestCase
  def test_article_stats_partition_table_name
    assert_equal "article_stats_y2015m01", ArticleStat.partition_table_name(1,2015)
  end

  def test_article_stats_create_partition
    ArticleStat.create_partition(1,2015)
    assert_equal true, ActiveRecord::Base.connection.data_source_exists?("article_stats_y2015m01")
  end

  def test_article_stats_trigger_statement_for
    months_and_years = [[9, 2015], [10, 2015], [11, 2015]]
    statement = <<-SQL
          CREATE OR REPLACE FUNCTION article_stats_insert_trigger()
          RETURNS TRIGGER AS $$
          BEGIN
              IF ( NEW.logdate >= DATE '2015-09-01' AND
                   NEW.logdate < DATE '2015-10-01' ) THEN
                  INSERT INTO article_stats_y2015m09 VALUES (NEW.*);
              ELSIF ( NEW.logdate >= DATE '2015-10-01' AND
                   NEW.logdate < DATE '2015-11-01' ) THEN
                  INSERT INTO article_stats_y2015m10 VALUES (NEW.*);
              ELSIF ( NEW.logdate >= DATE '2015-11-01' AND
                   NEW.logdate < DATE '2015-12-01' ) THEN
                  INSERT INTO article_stats_y2015m11 VALUES (NEW.*);
              END IF;
              RETURN NULL;
          END;
          $$
          LANGUAGE plpgsql;

          DROP TRIGGER IF EXISTS insert_article_stats_trigger ON article_stats;
          CREATE TRIGGER insert_article_stats_trigger
              BEFORE INSERT ON article_stats
              FOR EACH ROW EXECUTE PROCEDURE article_stats_insert_trigger();
    SQL

    assert_equal statement, ArticleStat.trigger_statement(months_and_years)
  end

  def test_article_stats_get_trigger_body
    months_and_years = [[9, 2015], [10, 2015], [11, 2015]]
    statement = <<-SQL
          BEGIN
              IF ( NEW.logdate >= DATE '2015-09-01' AND
                   NEW.logdate < DATE '2015-10-01' ) THEN
                  INSERT INTO article_stats_y2015m09 VALUES (NEW.*);
              ELSIF ( NEW.logdate >= DATE '2015-10-01' AND
                   NEW.logdate < DATE '2015-11-01' ) THEN
                  INSERT INTO article_stats_y2015m10 VALUES (NEW.*);
              ELSIF ( NEW.logdate >= DATE '2015-11-01' AND
                   NEW.logdate < DATE '2015-12-01' ) THEN
                  INSERT INTO article_stats_y2015m11 VALUES (NEW.*);
              END IF;
              RETURN NULL;
          END;
    SQL

    assert_equal statement, ArticleStat.get_trigger_body(months_and_years)
  end

  def test_article_stats_partition_exists?
    ArticleStat.create_partition(1,2011)
    assert_equal true, ArticleStat.partition_exists?(1,2011)
  end

  def test_article_stats_drop_partition_table
    ArticleStat.create_partition(2,2014)
    ArticleStat.drop_partition(2, 2014)
    assert_equal false, ActiveRecord::Base.connection.data_source_exists?("article_stats_y2014m02")
  end
end
