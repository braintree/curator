require 'curator/repository'
require 'active_support/core_ext/hash/indifferent_access'

module Curator
  module Repository
    class Settings
      attr_reader :all, :changed
      alias_method :to_hash, :all

      def initialize(current_settings = {})
        @all = HashWithIndifferentAccess.new(current_settings)
        clear_dirty!
      end

      def set(property, value)
        original_value = all[property]
        unless value == original_value
          all[property] = value
          changed[property] = value
        end
      end

      def enable(property)
        set(property, true)
      end

      def disable(property)
        set(property, false)
      end

      def [](property)
        all[property]
      end

      def uncommitted?
        changed.any?
      end

      def clear_dirty!
        @changed = HashWithIndifferentAccess.new
      end

      def apply!(opts = {})
        data_store = opts.fetch(:data_store)
        collection_name = opts.fetch(:collection_name)
        clear_dirty! if data_store.update_settings!(collection_name, changed)
      end
    end
  end
end
