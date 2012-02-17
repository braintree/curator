module Curator
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization" do |app|
      Curator.bucket_prefix = app.class.name.split("::").first.underscore
      Curator.environment = Rails.env
      Curator.migrations_path = Rails.root.join('db', 'migrate')
      Curator.riak_config_file = Rails.root.join('config', 'riak.yml')
    end
  end
end
