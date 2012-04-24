require 'ostruct'

module Curator
  module Memory
    class DataStore
      def self.remove_all_keys
        @data = {}
      end
      class << self
        alias :reset! :remove_all_keys
      end

      def self.save(options)
        bucket = _bucket_name(options[:collection_name])
        object = options[:value]
        key = options[:key]
        indexes = options.fetch(:index, {})

        key = _generate_key(bucket) unless key

        _records(bucket).store(key, object)
        indexes.each do |index_name, index_data|
          index = _index(bucket, index_name)

          _normalized_index_values(index_data).each do |index_value|
            index[index_value] ||= []
            index[index_value] << key unless index[index_value].include?(key)
          end
        end

        key
      end

      def self.delete(collection_name, key)
        bucket = _bucket_name(collection_name)
        _records(bucket).delete(key)
        _indices(bucket).each_key do |name|
          index = _index(bucket, name)
          index.each do |value, keys|
            next unless keys.include?(key)
            index[value].delete(key)
          end
          index.delete_if { |value, keys| keys.empty? }
        end
      end

      def self.find_by_key(collection_name, key)
        bucket = _bucket_name(collection_name)
        value = _records(bucket).fetch(key, nil)
        return if value.nil?
        {:key => key, :data => value}
      end

      def self.find_by_index(collection_name, index_name, query)
        return [] if query.nil?
        bucket = _bucket_name(collection_name)
        index = _index(bucket, index_name)
        keys = case query
               when Range
                 keys = index.keys.select do |key|
                   key.between?(query.first, query.last)
                 end
                 index.values_at(*keys).flatten
               else
                 index.fetch(query, [])
               end
        keys.map do |key|
          find_by_key(collection_name, key)
        end
      end

      def self._data
        @data ||= {}
      end

      def self._bucket(bucket)
        _data[bucket] ||= {}
      end

      def self._records(bucket)
        _bucket(bucket)[:records] ||= {}
      end

      def self._indices(bucket)
        _bucket(bucket)[:indices] ||= {}
      end

      def self._index(bucket, index_name)
        _indices(bucket)[index_name] ||= {}
      end

      def self._normalized_index_values(indexed_data)
        if indexed_data.is_a?(Array)
          indexed_data
        else
          [indexed_data]
        end
      end

      def self._generate_key(bucket)
        keys = _records(bucket).keys
        keys = [0] if keys.empty?
        keys.max.next
      end

      def self._bucket_name(name)
        "#{Curator.config.environment}:#{name}"
      end
    end
  end
end
