require 'sequel'
require 'sequel/extensions/pg_array'
require 'securerandom'
require 'active_support/core_ext/hash/except'

module Curator
  module Postgresql
    class DataStore
      def self.client
        yml_config = YAML.load(File.read(Curator.config.postgresql_config_file))[Curator.config.environment]
        @client ||= Sequel.postgres(yml_config).extend(Sequel::Postgres::PGArray::DatabaseMethods)
      end

      def self.save(options)
        table_name = options[:collection_name]
        key = options[:key] || SecureRandom.hex
        value = _convert_values(table_name, options[:value])
        table = client[table_name.to_sym]

        if table.filter(:key => key).empty?
          table.insert(value.merge(:key => key))
        else
          table.filter(:key => key).update(value)
        end

        key
      end

      def self.delete(table_name, key)
        client[table_name.to_sym].filter(:key => key).delete
      end

      def self.find_by_key(table_name, key)
        _map_row client[table_name.to_sym][:key => key]
      end

      def self.find_by_index(table_name, column, value)
        if _array_column?(table_name, column)
          client[table_name.to_sym].filter("? = ANY(?)", value, column).all.map(&method(:_map_row))
        else
          client[table_name.to_sym].filter(column.to_sym => value).all.map(&method(:_map_row))
        end
      end

      def self.reset!

      end

      def self._array_column?(table_name, column)
        client.schema(table_name).any? do |field, schema|
          field == column && schema[:type].to_s =~ /array/
        end
      end

      def self._convert_values(table_name, values)
        converted_values = {}
        values.each do |column, value|
          if _array_column?(table_name, column)
            converted_values[column] = value.pg_array
          else
            converted_values[column] = value
          end
        end
        converted_values
      end

      def self._map_row(row)
        return unless row
        value = row.except(:id, :key).map { |k,v| [k.to_s, v] }.reject {|(_,v)| v.nil? }
        { :key => row[:key], :data => Hash[value] }
      end
    end
  end
end
