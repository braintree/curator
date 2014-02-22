module Curator
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization" do |app|
      Curator.configure(:riak) do |config|
        config.bucket_prefix = app.class.name.split("::").first.underscore
        config.environment = Rails.env
        config.migrations_path = Rails.root.join('db', 'migrate')
        config.riak_config_file = Rails.root.join('config', 'riak.yml')
      end
    end

    rake_tasks do
      tasks = Dir[File.join(File.dirname(__FILE__),'tasks/*.rake')]
      tasks.each { |f| load f }
    end
  end
end
