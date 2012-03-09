require 'active_support/core_ext/kernel/reporting'

module Curator
  module ResettableRiak
    class DataStore < Riak::DataStore
      def self.bucket_prefix
        job = "#{ENV['JOB_NAME'].gsub(/[^[:alnum:]]/, '_')}" if ENV['JOB_NAME'].present?
        [Curator.config.bucket_prefix, job, Curator.config.environment].compact.join(':')
      end

      def self.exclude_from_reset
        @exclude_from_reset = true
        yield
        @exclude_from_reset = false
      end

      def self.remove_all_keys
        silence_warnings do
          buckets = client.buckets.select { |bucket| bucket.name.start_with?(DataStore.bucket_prefix) }
          buckets.each do |bucket|
            bucket.keys do |keys|
              keys.each { |key| bucket.delete(key) }
            end
          end
        end
      end

      def self.reset!
        @bucket_names ||= {}
        deletable_buckets = @bucket_names.each do |bucket_name, keys|
          bucket = _bucket(bucket_name)
          keys.each {|key| bucket.delete(key)}
        end
        @bucket_names = {}
      end

      def self.save(options)
        key = super

        unless @exclude_from_reset
          @bucket_names ||= {}
          @bucket_names[options[:collection_name]] ||= []
          @bucket_names[options[:collection_name]] << key
        end

        key
      end
    end
  end
end
