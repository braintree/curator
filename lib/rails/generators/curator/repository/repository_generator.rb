require 'rails/generators/named_base'

module Curator
  module Generators
    class RepositoryGenerator < Rails::Generators::NamedBase
      desc 'Creates a Curator repository in app/repositories'
      argument :attributes, :type => :array, :default => [], :banner => "field field"
      check_class_collision :suffix => 'Repository'

      source_root File.expand_path("../templates", __FILE__)

      def create_model_file
        template 'repository.rb', File.join('app/repositories', class_path, "#{file_name}.rb")
      end

      hook_for :test_framework
    end
  end
end
