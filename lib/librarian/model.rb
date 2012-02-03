require 'active_support'

module Librarian
  module Model
    extend ActiveSupport::Concern

    included do
      attr_accessor :created_at, :updated_at
      attr_writer :version
    end

    def ==(other)
      self.id == other.id
    end

    def version
      @version || self.class.version
    end

    module ClassMethods
      def current_version(number)
        @version = number
      end

      def version
        @version || 0
      end
    end
  end
end
