module Partitionable
  module ActsAsPartitionable
    extend ActiveSupport::Concern

    included do
      before_save :create_partition
    end

    module ClassMethods
      def acts_as_partitionable(options = {})
        cattr_accessor :index_fields
        self.index_fields = options[:index_fields]

        def partition_name(month, year)
          formatted_month = sprintf('%02d', month)
          "#{self.table_name}_y#{year}m#{formatted_month}"
        end

        def create_partition(month, year)
          ActiveRecord::Base.connection.execute create_table_statement(month, year)
        end

        def create_table_statement(month, year)
          table = partition_name(month, year)
          index_name = "#{table}_#{index_fields.join('_')}"
          first_day_of_month = Date.civil(year, month, 1)
          first_day_next_month = (first_day_of_month + 1.month)
          <<-SQL
          CREATE TABLE #{table} (
              CHECK ( logdate >= DATE '#{first_day_of_month.to_s}' AND logdate < DATE '#{first_day_next_month.to_s}' )
          ) INHERITS (#{self.table_name});
          CREATE INDEX #{index_name} ON #{table} (#{index_fields.join(',')});
          SQL
        end

        def drop_partition(month, year)
          name = partition_name(month, year)
          index_name = "#{name}_#{index_fields.join('_')}"
          function_name = "#{name}_insert_trigger_function()"
          trigger_name = "#{name}_trigger"
          ActiveRecord::Base.connection.execute(
            <<-SQL
          DROP TABLE IF EXISTS #{name};
          DROP INDEX IF EXISTS #{index_name};
          DROP FUNCTION IF EXISTS #{function_name} CASCADE;
          DROP TRIGGER IF EXISTS #{trigger_name} ON #{self.table_name} CASCADE;
            SQL
          )
        end

        def trigger_statement months_and_years
          trigger_body = get_trigger_body(months_and_years)
          statement = ""
          statement += <<-SQL
          CREATE OR REPLACE FUNCTION #{self.table_name}_insert_trigger()
          RETURNS TRIGGER AS $$
          SQL

          statement += trigger_body
          statement += <<-SQL
          $$
          LANGUAGE plpgsql;

          DROP TRIGGER IF EXISTS insert_#{self.table_name}_trigger ON #{self.table_name};
          CREATE TRIGGER insert_#{self.table_name}_trigger
              BEFORE INSERT ON #{self.table_name}
              FOR EACH ROW EXECUTE PROCEDURE #{self.table_name}_insert_trigger();
          SQL
          statement
        end

        def get_trigger_body months_and_years

          statement = ""
          statement += <<-eos
          BEGIN
          eos

          months_and_years.each_with_index do |data, index|

            first_day_of_month = Date.civil(data[1], data[0], 1)
            first_day_next_month = (first_day_of_month + 1.month)
            if index == 0
              statement += <<-eos
              IF ( NEW.logdate >= DATE '#{first_day_of_month}' AND
                   NEW.logdate < DATE '#{first_day_next_month}' ) THEN
                  INSERT INTO #{partition_name(data[0], data[1])} VALUES (NEW.*);
              eos
            else
              statement += <<-eos
              ELSIF ( NEW.logdate >= DATE '#{first_day_of_month}' AND
                   NEW.logdate < DATE '#{first_day_next_month}' ) THEN
                  INSERT INTO #{partition_name(data[0], data[1])} VALUES (NEW.*);
              eos
            end
          end
          statement += <<-eos
              END IF;
              RETURN NULL;
          END;
          eos
        end

        def partition_exists?(month, year)
          ActiveRecord::Base.connection.data_source_exists? partition_name(month, year)
        end

        include Partitionable::ActsAsPartitionable::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def has_partition?
        month = self.logdate.month
        year = self.logdate.year
        self.class.partition_exists? month,year
      end

      def create_partition
        month = self.logdate.month
        year = self.logdate.year
u       self.class.create_partition(month,year) unless has_partition?
      end
    end
  end
end
