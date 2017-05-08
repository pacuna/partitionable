module Partitionable
  module ActsAsPartitionable
    extend ActiveSupport::Concern

    included do
      before_save :create_partition_from_record
    end

    module ClassMethods
      def acts_as_partitionable(options = {})
        cattr_accessor :logdate_attr
        cattr_accessor :indices
        self.indices = [
          {
            name: options[:name],
            fields: options[:index_fields],
            where: options[:where]
          }
        ] + (options[:indices] || [])
        self.logdate_attr = options[:logdate_attr]

        def partition_name(month, year)
          formatted_month = sprintf('%02d', month.to_i)
          "#{self.table_name}_y#{year}m#{formatted_month}"
        end

        def create_partition(month, year)
          ActiveRecord::Base.connection.execute create_table_statement(month, year)
        end

        def create_table_statement(month, year)
          table = partition_name(month, year)
          first_day_of_month = Date.civil(year, month, 1)
          first_day_next_month = (first_day_of_month + 1.month)
          <<-SQL
          CREATE TABLE #{table} (
              CHECK ( #{self.logdate_attr} >= DATE '#{first_day_of_month.to_s}' AND #{self.logdate_attr} < DATE '#{first_day_next_month.to_s}' )
          ) INHERITS (#{self.table_name});
          #{create_index_statements(month, year)}
          SQL
        end

        def create_index_statements(month, year)
          table = partition_name(month, year)
          indices.map do |index|
            where = index[:where].nil? ? '' : " where #{index[:where]}"
            name = index_name(month, year, index)
            "CREATE INDEX #{name} ON #{table} (#{index[:fields].join(',')})#{where};"
          end.join("\n")
        end

        def index_name(month, year, index)
          table = partition_name(month, year)
          if index[:name].nil?
            "#{table}_#{index[:fields].join('_')}"
          else
            "#{table}_#{index[:name]}"
          end
        end

        def drop_partition(month, year)
          name = partition_name(month, year)
          function_name = "#{name}_insert_trigger_function()"
          trigger_name = "#{name}_trigger"
          drop_indices = indices.map { |i| "DROP INDEX IF EXISTS #{index_name(month, year, i)};" }
          ActiveRecord::Base.connection.execute(
            <<-SQL
          DROP TABLE IF EXISTS #{name};
          #{drop_indices.join("\n")}
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

            first_day_of_month = Date.civil(data[1].to_i, data[0].to_i, 1)
            first_day_next_month = (first_day_of_month + 1.month)
            if index == 0
              statement += <<-eos
              IF ( NEW.#{self.logdate_attr} >= DATE '#{first_day_of_month}' AND
                   NEW.#{self.logdate_attr} < DATE '#{first_day_next_month}' ) THEN
                  INSERT INTO #{partition_name(data[0], data[1])} VALUES (NEW.*);
              eos
            else
              statement += <<-eos
              ELSIF ( NEW.#{self.logdate_attr} >= DATE '#{first_day_of_month}' AND
                   NEW.#{self.logdate_attr} < DATE '#{first_day_next_month}' ) THEN
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

        def update_trigger
          ActiveRecord::Base.connection.execute updated_trigger_statement
        end

        def updated_trigger_statement
          tables = ActiveRecord::Base.connection.tables.select{|t| t =~ /#{self.table_name}_y[0-9]{4}m[0-9]{2}/}
          months_and_years = tables.map {|t| [t.match(/m\K[0-9]{2}/)[0], t.match(/y\K[0-9]{4}/)[0]]}
          trigger_statement months_and_years.sort_by{|month, year| [year.to_i, month.to_i]}
        end

        include Partitionable::ActsAsPartitionable::LocalInstanceMethods
      end
    end

    module LocalInstanceMethods
      def has_partition?
        month = self.send(self.class.logdate_attr.to_sym).month
        year = self.send(self.class.logdate_attr.to_sym).year
        self.class.partition_exists? month,year
      end

      def create_partition_from_record
        return if has_partition?

        month = self.send(self.class.logdate_attr.to_sym).month
        year = self.send(self.class.logdate_attr.to_sym).year
        self.class.create_partition(month,year)
        self.class.update_trigger
      end
    end
  end
end
