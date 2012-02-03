require 'active_support/core_ext/kernel/reporting'

module Riak
  class Cleaner
    def self.remove_all_keys
      riak = Riak::DataStore.client

      silence_warnings do
        buckets = riak.buckets.select { |bucket| bucket.name.start_with?(Riak::DataStore.bucket_prefix) }
        buckets.each do |bucket|
          bucket.keys do |keys|
            keys.each { |key| bucket.delete(key) }
          end
        end
      end
    end
  end
end
