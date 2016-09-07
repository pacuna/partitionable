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
      end
    end
  end
end
