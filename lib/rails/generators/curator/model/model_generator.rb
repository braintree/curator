require 'rails/generators/named_base'

module Curator
  module Generators
    class ModelGenerator < Rails::Generators::NamedBase
      desc 'Creates a Curator model in app/models'
      argument :attributes, :type => :array, :default => [], :banner => "field field"
      check_class_collision

      source_root File.expand_path("../templates", __FILE__)

      def create_model_file
        template 'model.rb', File.join('app/models', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
