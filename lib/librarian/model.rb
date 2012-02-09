require 'active_support'
require 'active_model'

module Librarian
  module Model
    extend ActiveSupport::Concern
    include ActiveModel::Conversion

    included do
      attr_accessor :created_at, :updated_at
      attr_writer :version
    end

    def persisted?
      id.present?
    end

    def ==(other)
      self.id == other.id
    end

    def version
      @version || self.class.version
    end

    module ClassMethods
      include ActiveModel::Naming

      def current_version(number)
        @version = number
      end

      def version
        @version || 0
      end
    end
  end
end
