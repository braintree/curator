module Curator
  class Railtie < Rails::Railtie
    initializer "railtie.configure_rails_initialization" do
      Curator.environment = Rails.env
      Curator.riak_config_file = Rails.root.join('config', 'riak.yml')
      Curator.migrations_path = Rails.root.join('db', 'migrate')
    end
  end
end
