require 'sequel'
require 'securerandom'
require 'active_support/core_ext/hash/except'

module Curator
  module Sql
    class DataStore
      def self.client
        @client ||= Sequel.connect(Curator.config.uri)
      end

      def self.save(options)
        table_name = options[:collection_name]
        key = options[:key] || SecureRandom.hex
        value = options[:value]
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
        client[table_name.to_sym].filter(column.to_sym => value).all.map(&method(:_map_row))
      end

      def self.reset!

      end

      def self._map_row(row)
        return unless row
        value = row.except(:id, :key).map { |k,v| [k.to_s, v] }.reject {|(_,v)| v.nil? }
        { :key => row[:key], :data => Hash[value] }
      end

    end
  end
end
