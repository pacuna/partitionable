module Partitionable
  module ActsAsPartitionable
    extend ActiveSupport::Concern

    included do
    end

    module ClassMethods
      def acts_as_partitionable

        def partition_table_name(month, year)
          formatted_month = sprintf('%02d', month)
          "#{self.table_name}_y#{year}m#{formatted_month}"
        end

        def create_table_for(month, year)
          table = partition_table_name(month, year)
          index_name = "#{table}_logdate_site"
          first_day_of_month = Date.civil(year, month, 1)
          first_day_next_month = (first_day_of_month + 1.month)

          ActiveRecord::Base.connection.execute(
            <<-SQL
          CREATE TABLE #{table} (
              CHECK ( logdate >= DATE '#{first_day_of_month.to_s}' AND logdate < DATE '#{first_day_next_month.to_s}' )
          ) INHERITS (#{self.table_name});
          CREATE INDEX #{index_name} ON #{table} (site, token);
            SQL
          )
        end
      end
    end
  end
end
