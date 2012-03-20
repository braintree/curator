require 'rails/generators/named_base'

module Curator
  module Generators
    class Base < Rails::Generators::NamedBase

      def self.source_root
        @_curator_source_root ||= File.expand_path("../#{base_name}/#{generator_name}/templates", __FILE__)
      end
    end
  end
end
