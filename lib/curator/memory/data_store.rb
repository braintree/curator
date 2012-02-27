require 'ostruct'

module Curator::Memory
  class DataStore
    class << self
      def remove_all_keys
        @data = {}
      end
      alias :reset! :remove_all_keys

      def save(options)
        bucket = _bucket_name(options[:collection_name])
        object = options[:value]
        key = options[:key]
        indexed_values = options.fetch(:index, {})

        key = _generate_key(bucket) unless key

        _records(bucket).store(key, object)
        indexed_values.each do |index_name, indexed_value|
          index = _index(bucket, index_name)
          index[indexed_value] ||= []
          index[indexed_value] << key unless index[indexed_value].include?(key)
        end

        OpenStruct.new(:key => key)
      end

      def delete(collection_name, key)
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

      def find_by_key(collection_name, key)
        bucket = _bucket_name(collection_name)
        value = _records(bucket).fetch(key, nil)
        return if value.nil?
        {:key => key, :data => value}
      end

      def find_by_index(collection_name, index_name, query)
        return [] if query.nil?
        bucket = _bucket_name(collection_name)
        index = _index(bucket, index_name)
        keys = case query
        when Range
          first = _convert_for_query(query.first)
          last = _convert_for_query(query.last)
          keys = index.keys.select do |key|
            key = _convert_for_query(key)
            key.between?(first, last)
          end
          index.values_at(*keys).flatten
        else
          index.fetch(query, [])
        end
        keys.map do |key|
          find_by_key(collection_name, key)
        end
      end

      def _convert_for_query(value)
        Time.parse(value.to_s)
      rescue ArgumentError
        value
      end

      def _data
        @data ||= {}
      end

      def _bucket(bucket)
        _data[bucket] ||= {}
      end

      def _records(bucket)
        _bucket(bucket)[:records] ||= {}
      end

      def _indices(bucket)
        _bucket(bucket)[:indices] ||= {}
      end

      def _index(bucket, index_name)
        _indices(bucket)[index_name] ||= {}
      end

      def _generate_key(bucket)
        keys = _records(bucket).keys
        keys = [0] if keys.empty?
        keys.max.next
      end

      def _bucket_name(name)
        "#{Curator.config.environment}:#{name}"
      end
    end
  end
end
